#!/usr/bin/env bash
#
# setup-gitnexus.sh — Pre-warm GitNexus indexes for a known set of repos.
#
# GitNexus is a MANUAL human tool here (web UI / wiki / architecture maps), driven by the
# `gnx` wrapper (dotfiles/dot-local/bin/gnx → ~/.local/bin/gnx). This script just pre-builds
# indexes so `gnx serve` is ready to browse without waiting — handy on a new machine. For
# day-to-day use, prefer `gnx index <path>` on demand.
#
# Every repo is indexed via `gnx index`, i.e. `--index-only --embeddings`: ZERO files are
# written into the repo (no CLAUDE.md/AGENTS.md/skills), embeddings are built locally, and
# repos with no embeddable content fall back to structure-only automatically.
#
# Idempotent: `gnx index` skips a repo already current with git HEAD. FORCE=1 re-indexes all.
# A failure on one repo is logged and does NOT abort the rest.
#
# Usage:
#   bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh
#   FORCE=1 bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh   # force full re-index
#
# Repo paths come from the gitignored scripts/setup-gitnexus.local (copy the .example):
#   GITNEXUS_PRIMARY_REPO    extra repo to index alongside dotfiles
#   GITNEXUS_PROJECTS_DIR    dir whose immediate subdirs are repos to index

# Note: deliberately NOT using `set -e` — one bad repo must not kill the whole run.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
[ -f "$SCRIPT_DIR/setup-gitnexus.local" ] && . "$SCRIPT_DIR/setup-gitnexus.local"

# Use the repo's own gnx (works before stow puts it on PATH).
GNX="$SCRIPT_DIR/../dotfiles/dot-local/bin/gnx"
[ -x "$GNX" ] || { echo "✖ gnx not found/executable at $GNX" >&2; exit 1; }
command -v gitnexus >/dev/null 2>&1 \
  || { echo "✖ gitnexus not on PATH. Install it (Homebrew); gnx wraps it." >&2; exit 1; }

FORCE_ARG=""
[ "${FORCE:-0}" = "1" ] && FORCE_ARG="--force"

# Build the repo list: dotfiles + optional primary + each immediate subdir of the projects dir.
repos=("$HOME/Projects/dotfiles")
[ -n "${GITNEXUS_PRIMARY_REPO:-}" ] && repos+=("$GITNEXUS_PRIMARY_REPO")
if [ -n "${GITNEXUS_PROJECTS_DIR:-}" ] && [ -d "${GITNEXUS_PROJECTS_DIR}" ]; then
  for d in "$GITNEXUS_PROJECTS_DIR"/*/; do repos+=("${d%/}"); done
elif [ -n "${GITNEXUS_PROJECTS_DIR:-}" ]; then
  echo "  ⤷ projects dir not found (GITNEXUS_PROJECTS_DIR): $GITNEXUS_PROJECTS_DIR" >&2
fi

ok=() failed=() skipped=()
for repo in "${repos[@]}"; do
  if [ ! -d "$repo/.git" ]; then
    echo "  ⤷ skip (not a git repo): $repo"; skipped+=("$repo"); continue
  fi
  echo "==> $repo"
  if bash "$GNX" index "$repo" $FORCE_ARG; then
    ok+=("$repo")
  else
    echo "  ✖ FAILED: $repo" >&2; failed+=("$repo")
  fi
done

echo
echo "================= Summary ================="
echo "  Indexed OK : ${#ok[@]}"
echo "  Skipped    : ${#skipped[@]}  (not git repos)"
echo "  Failed     : ${#failed[@]}"
[ "${#failed[@]}" -gt 0 ] && printf '    ✖ %s\n' "${failed[@]}"
echo "==========================================="
echo
gitnexus list

# Non-zero exit if anything failed, so callers/CI can detect it.
[ "${#failed[@]}" -eq 0 ]
