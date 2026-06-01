---
description: Refresh the dotfiles reference docs against upstream documentation and flag stale rules
argument-hint: "[force]"
---

# Dotfiles self-update

Fetch upstream documentation for each configured tool, review every reference doc with parallel subagents, auto-apply doc updates, and flag any lean rule that needs a matching change.

This is the migrated successor of the old `/dotfiles self-update` skill cookbook. Reference docs now live in `.claude/dotfiles-ref/`; the lean auto-load rules live in `.claude/rules/`.

## Variables

```
REF_DIR    = .claude/dotfiles-ref      # full reference docs (reviewed/updated here)
RULES_DIR  = .claude/rules             # lean path-scoped rules (flagged if a ref change affects them)
STATE_FILE = .claude/dotfiles-ref/.self-update-state.json
```

### Documentation sources

| Source | URL | Maps to ref |
|--------|-----|-------------|
| Ghostty docs | https://ghostty.org/docs | GHOSTTY.md |
| Starship config | https://starship.rs/config/ | STARSHIP.md |
| Catppuccin releases | https://github.com/catppuccin/catppuccin/releases | TOOLS.md, GHOSTTY.md, THEME-XDG.md |
| Nushell config | https://www.nushell.sh/book/configuration.html | TOOLS.md |
| GNU Stow manual | https://www.gnu.org/software/stow/manual/stow.html | STOW.md |
| TPM releases | https://github.com/tmux-plugins/tpm/releases | TMUX.md |
| Neovim docs/news | https://neovim.io/doc/user/news.html | NEOVIM.md |

## Workflow

### Step 0 — Read state

Read `$STATE_FILE` for `lastUpdateTimestamp`. Missing/corrupt → treat as first run. If `$ARGUMENTS` is `force`, review regardless of recency.

### Step 1 — Launch parallel review agents

Launch one `general-purpose` subagent per reference doc (model: sonnet). Each agent:
1. WebFetches its assigned upstream doc(s) from the table above.
2. For config-drift docs (ZSH, TMUX, NEOVIM), also reads the **actual config** under `dotfiles/` to detect drift.
3. Reads its `$REF_DIR/<DOC>.md`.
4. Returns structured findings.

Assign: GHOSTTY.md, STARSHIP.md, TOOLS.md (Nushell + CLI tools), ZSH.md (drift vs `dot-zshrc`/`dot-zprofile`/`aliases.zsh`), TMUX.md (TPM + actual `tmux/`), NEOVIM.md (Neovim news + actual `nvim/`), STOW.md.

**Agent output contract:**

```
OUTDATED_SECTIONS:
- section_name / issue / suggested_fix
NEW_CONTENT:
- location / content / reason
CORRECTIONS:
- line_or_section / current / corrected / reason
AFFECTS_RULE: <rules/<tool>.md or "none">   # does this change touch a fact mirrored in the lean rule?
NO_CHANGES_NEEDED: true/false
SUMMARY: one line
```

Be conservative: only flag confident, doc-verified changes. Verify any config-level claim against the real file before acting.

### Step 2 — Verify, then apply

For each finding, **verify against the source of truth** (upstream doc or actual config) before editing — never "correct" a ref to match a buggy config. Apply corrections first, then new content. If a finding reveals a real **config bug** (not a doc issue), do NOT bake it into the ref — surface it to the user separately.

### Step 3 — Sync lean rules

For every finding with `AFFECTS_RULE != none`, open the named `$RULES_DIR/<tool>.md` and update the distilled fact/gotcha so the lean rule and its ref agree. Keep rules lean — update the specific line, don't paste reference prose.

### Step 4 — Update state

Write `$STATE_FILE`:

```json
{
  "lastUpdateTimestamp": "<ISO>",
  "updateHistory": [
    { "timestamp": "<ISO>", "filesUpdated": ["..."], "rulesUpdated": ["..."], "changesApplied": N, "configBugsFlagged": ["..."] }
  ]
}
```

Prepend the new entry; keep prior history.

### Step 5 — Report

Output a table (ref | changes | status), a rules-synced list, any config bugs flagged for the user, and totals.

## Error handling

| Error | Action |
|-------|--------|
| WebFetch failure | Continue with available sources, note in report |
| Subagent timeout | Mark ref "review skipped", continue |
| State file missing/corrupt | Treat as first run |
| Edit failure | Log, continue, report at end |

## Up-to-date detection

If nothing upstream changed since `lastUpdateTimestamp` (and `force` not passed), skip steps 2–4 and report "Already up to date."
