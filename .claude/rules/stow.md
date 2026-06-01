---
paths:
  - ".stowrc"
  - "**/.stow-local-ignore"
  - ".stow-global-ignore"
---

# GNU Stow rules

This repo deploys configs as symlinks via GNU Stow.

## Critical
- **ALWAYS run `stow .` from the project root. NEVER `stow <package-name>`.** `.stowrc` only applies to `stow .`; running `stow dot-claude` creates wrong symlinks (e.g. `~/dot-claude/`).
- `.stowrc`: `--dir=./dotfiles`, `--target=~/`, `--dotfiles` (so `dot-zshrc` → `~/.zshrc`), plus `--ignore=` patterns (`\.DS_Store`, `cli-plugins`).

## Working with symlinks
- Edit the **source** (`dotfiles/dot-*`); deployed `~/...` paths are symlinks to it — same file. Do **not** diff source vs deployed to check drift; they can't diverge.
- Add a new config: create `dotfiles/dot-<name>` (or `dotfiles/dot-config/<app>/...`), then `stow .`.
- `.stow-local-ignore` in a package **overrides** the built-in defaults — re-add the defaults you still want.
- `.stowrc` supports `$VAR`/`${VAR}` expansion. Audit a target with `chkstow --badlinks|--aliens|--list`.

Full reference: [.claude/dotfiles-ref/STOW.md](../dotfiles-ref/STOW.md)
