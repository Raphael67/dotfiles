---
name: gitnexus-cli
description: "Use when the user wants to run GitNexus to explore or document a codebase: build/refresh its index, open the web UI, generate a wiki, or check status. GitNexus is a manual human tool here — help the user run the `gnx` commands. Examples: \"index this repo with gitnexus\", \"open the gitnexus UI\", \"generate a wiki for this project\", \"gnx\"."
---

# GitNexus — running it via `gnx`

GitNexus is set up as a **manual human exploration + documentation tool** (web UI, wiki,
architecture maps), **not** an agent tool. There is no MCP server and no autonomous use.
Your job is to help the user drive it through the `gnx` wrapper (`~/.local/bin/gnx`, stowed
from `dotfiles/dot-local/bin/gnx`). For *agentic* "what does this change touch?" reasoning,
use **`sem`** instead — see the `gitnexus-guide` skill for the when-to-use-which split.

## The two core commands

```bash
gnx index <path>     # build / refresh the knowledge graph (+ local embeddings) for a repo
gnx serve            # open the web UI at http://127.0.0.1:4747 (browses ALL indexed repos)
```

Typical flow: `gnx index ~/path/to/repo` to (re)build, then `gnx serve` (or `gnx ui` to also
open the browser). `serve` takes no path — the UI lists every repo in the registry.

## All commands

| Command | What it does |
| ------- | ------------ |
| `gnx index <path> [--fast] [--force]` | (Re)index a repo. Always `--index-only` (writes **nothing** into the repo). `--fast` skips embeddings; `--force` re-indexes even if current. |
| `gnx serve [--port N] [--open]` | Start the web UI (all registered repos). `--open` also opens the browser. |
| `gnx ui [--port N]` | Serve in the **background** and open the browser. Stop it with `pkill -f 'gitnexus serve'`. |
| `gnx refresh-all [--force]` | Re-index every repo in the registry. |
| `gnx wiki <path>` | Generate the markdown wiki for a repo (LLM-backed; may need an API key in `~/.gitnexus/config.json`). |
| `gnx status` / `gnx list` | Index freshness for the current repo / all registered repos. |
| `gnx clean <path>` | Delete a repo's index and unregister it. |
| `gnx doctor` | Runtime + embedding capabilities. |
| `gnx help` | Usage. |

## Key facts

- **`index` never pollutes the repo.** It runs `gitnexus analyze <path> --index-only --embeddings`,
  so no `CLAUDE.md` / `AGENTS.md` / skill files are written into the target — safe on
  team-shared repos.
- **Embeddings are local & free** (ONNX). Pure shell/Terraform repos can't persist embeddings;
  `gnx index` detects the `without persisted embeddings` error and retries structure-only.
- **Idempotent.** `gnx index` skips repos already current with git HEAD; re-run it before
  browsing to refresh after code changes (use `--force` to rebuild regardless).
- **Storage.** Index lives in `<repo>/.gitnexus/lbug` (gitignored). Global state is only
  `~/.gitnexus/registry.json` and `~/.config/gitnexus/config.json`.

## Pre-warming on a new machine

```bash
bash ~/Projects/dotfiles/scripts/setup-gitnexus.sh   # indexes repos listed in
                                                     # scripts/setup-gitnexus.local (gitignored)
```

## Troubleshooting

- **`gitnexus: command not found`** → install GitNexus (Homebrew); `gnx` wraps the `gitnexus` binary.
- **UI won't load** → check the port (`gnx serve --port N`); kill a stray server: `pkill -f 'gitnexus serve'`.
- **Weak semantic search / no embeddings** → `gnx doctor` shows capability; rebuild with `gnx index <path> --force`.
- **Stale data in the UI** → `gnx index <path>` to refresh, then reload the page.
