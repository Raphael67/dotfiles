# claude-code-skills-bridge

A Cowork plugin that exposes your host-machine Claude Code skills (`~/.claude/skills/`) inside Cowork sessions.

## How it works

Cowork mounts an installed plugin's `skills/` directory read-only into the VM at session boot. The `cowork-skills` host command (a Python script in `~/.config/cowork-skills/sync.py`) copies skills from `~/.claude/skills/` into this plugin's `skills/` directory as real files. Cowork then auto-discovers them; they appear inside Cowork as `claude-code-skills-bridge:<skill-name>`.

```
~/.claude/skills/  --[cowork-skills sync]-->  <this plugin>/skills/  --[Cowork mount]-->  VM
```

No MCP server, no port, no daemon, no host networking. Cowork's plugin policy actively shadows third-party-declared remote MCPs with no-ops, so the only architecture that works is to pre-load real files into the plugin tree.

## Skills filtered out at sync

The sync skips skills that duplicate Cowork's bundled `anthropic-skills` plugin:
- `docx`, `pdf`, `pptx`, `xlsx`, `skill-creator`, `schedule`, `setup-cowork`, `consolidate-memory`

It also skips symlinks pointing **into** Cowork's own skills-plugin directory (the user often has those as cross-references).

## Daily workflow

| When | Run |
|---|---|
| First-time install | `~/.config/cowork-skills/install.sh` |
| Added a new skill to `~/.claude/skills/` | `cowork-skills` + restart Claude Desktop |
| Edited an existing skill | `cowork-skills` + restart Claude Desktop |

The Desktop restart is required because Cowork takes the snapshot of plugin contents at VM session boot.

## Caveats

- Some skills assume host-only tools (`bw-fetch`, host paths under `/Users/raphael/`). Inside the VM those won't exist; adapt as needed.
- The full skill content (including sub-files) is copied each sync, so the plugin can get larger if your skills include big assets.
- Removing a skill from `~/.claude/skills/` and re-running `cowork-skills` will remove it from the plugin too — the sync wipes and rebuilds `skills/`.

## Install (one-time, automatic)

`~/.config/cowork-skills/install.sh` does:
1. Copies this plugin into Cowork's `rpm/plugin_claude-code-skills-bridge/`.
2. Registers it in Cowork's `rpm/manifest.json` as `My Uploads`.
3. Runs the initial `sync.py` to populate `skills/` from `~/.claude/skills/`.
4. Tells you to restart Claude Desktop.
