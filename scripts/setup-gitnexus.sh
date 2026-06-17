#!/usr/bin/env bash
#
# setup-gitnexus.sh — Reproducibly (re)index key repos into GitNexus.
#
# Two tiers, by intent:
#   • Primary repos (dotfiles + your primary project) — personal repos. Full index
#     *with* agent-context injection (.claude/skills/gitnexus/, CLAUDE.md / AGENTS.md
#     sections). These are mine; I want the in-repo GitNexus context.
#   • Project repos (under $GITNEXUS_PROJECTS_DIR) — possibly team-shared. `--index-only`,
#     so the knowledge graph is built in .gitnexus/ but ZERO files are written into the
#     repo (no surprise git changes for teammates). Embeddings still on for semantic search.
#
# Idempotent: `gitnexus analyze` skips a repo already current with git HEAD. Pass FORCE=1
# to force a full re-index. A failure on one repo is logged and does NOT abort the rest.
#
# Usage:
#   bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh
#   FORCE=1 bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh        # full re-index
#   ONLY_PROJECTS=1 bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh # skip primary tier
#
# Real, private repo paths live in a gitignored sibling file sourced below:
#   scripts/setup-gitnexus.local   (copy from scripts/setup-gitnexus.local.example)
#
# Env overrides (set them in setup-gitnexus.local or your shell):
#   GITNEXUS_PRIMARY_REPO    extra primary repo to full-index alongside dotfiles
#   GITNEXUS_PROJECTS_DIR    dir whose immediate subdirs are project repos (index-only)
#   FORCE=1                  add --force to every analyze
#   ONLY_PROJECTS=1          index only the project repos (skip the primary tier)

# Note: deliberately NOT using `set -e` — one bad repo must not kill the whole run.
set -uo pipefail

# Machine-local, gitignored config — real repo paths live here, never committed.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
[ -f "$SCRIPT_DIR/setup-gitnexus.local" ] && . "$SCRIPT_DIR/setup-gitnexus.local"

PRIMARY_REPO="${GITNEXUS_PRIMARY_REPO:-}"
PROJECTS_DIR="${GITNEXUS_PROJECTS_DIR:-}"

FORCE_FLAG=""
[ "${FORCE:-0}" = "1" ] && FORCE_FLAG="--force"

if ! command -v gitnexus >/dev/null 2>&1; then
  echo "✖ gitnexus not found on PATH. Install with: npm install -g gitnexus@latest" >&2
  exit 1
fi

ok=()
failed=()
skipped=()
degraded=()   # indexed, but had to drop --embeddings (e.g. pure Terraform/shell repos)

# index <repo-path> [extra gitnexus flags...]
index() {
  local repo="$1"
  shift
  if [ ! -d "$repo/.git" ]; then
    echo "  ⤷ skip (not a git repo): $repo"
    skipped+=("$repo")
    return
  fi
  echo "▶ indexing: $repo  [flags: $* ${FORCE_FLAG}]"

  local out
  out="$(gitnexus analyze "$repo" "$@" ${FORCE_FLAG:+$FORCE_FLAG} 2>&1)"
  local rc=$?
  echo "$out"

  if [ "$rc" -eq 0 ]; then
    ok+=("$repo")
    return
  fi

  # Known-benign failure: --embeddings asked for, but the repo has no embeddable
  # content (e.g. pure Terraform/shell). GitNexus refuses to register an
  # embedding-less index. Retry structure-only so the repo still gets covered.
  if printf '%s' "$*" | grep -q -- '--embeddings' \
     && printf '%s' "$out" | grep -q 'without persisted embeddings'; then
    echo "  ⚠ no embeddable content — retrying structure-only (no --embeddings)"
    local rest=()
    local a
    for a in "$@"; do [ "$a" = "--embeddings" ] || rest+=("$a"); done
    if gitnexus analyze "$repo" "${rest[@]}" ${FORCE_FLAG:+$FORCE_FLAG}; then
      degraded+=("$repo")
      return
    fi
  fi

  echo "  ✖ FAILED: $repo" >&2
  failed+=("$repo")
}

if [ "${ONLY_PROJECTS:-0}" != "1" ]; then
  echo "=== Primary repos (full index + agent-context injection) ==="
  index "$HOME/Projects/dotfiles"       --embeddings
  [ -n "$PRIMARY_REPO" ] && index "$PRIMARY_REPO" --embeddings
  echo
fi

echo "=== Project repos (index-only, zero footprint + embeddings) ==="
if [ -n "$PROJECTS_DIR" ] && [ -d "$PROJECTS_DIR" ]; then
  for repo in "$PROJECTS_DIR"/*/; do
    index "${repo%/}" --index-only --embeddings
  done
else
  echo "  ⤷ projects dir not set/found (set GITNEXUS_PROJECTS_DIR): ${PROJECTS_DIR:-<unset>}" >&2
fi

echo
echo "================= Summary ================="
echo "  Indexed OK : ${#ok[@]}"
echo "  Degraded   : ${#degraded[@]}  (indexed structure-only; no embeddable content)"
if [ "${#degraded[@]}" -gt 0 ]; then
  printf '    ⚠ %s\n' "${degraded[@]}"
fi
echo "  Skipped    : ${#skipped[@]}  (not git repos)"
echo "  Failed     : ${#failed[@]}"
if [ "${#failed[@]}" -gt 0 ]; then
  printf '    ✖ %s\n' "${failed[@]}"
fi
echo "==========================================="
echo
gitnexus list

# Non-zero exit if anything failed, so callers/CI can detect it.
[ "${#failed[@]}" -eq 0 ]
