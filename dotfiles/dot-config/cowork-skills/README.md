# cowork-skills

Sync `~/.claude/skills/` into the `claude-code-skills-bridge` Cowork plugin so your Claude Code skills are usable inside Cowork sessions.

## Why this exists

Claude Cowork runs each session inside a Virtualization.framework VM. The VM cannot see your home directory, and Cowork's plugin policy explicitly **shadows** any plugin-declared HTTP MCP server with no-ops (host-side log: `Plugin "..." has remote MCP servers (...). Shadowing with no-ops to prevent SDK double-load.`). The only architecture Cowork accepts for third-party skills is **pre-loaded files inside the plugin's `skills/` directory**, which Cowork mounts read-only into the VM at session boot.

This tool does that copy. No daemon, no port, no MCP server.

See `~/.claude/skills/claude-expert/DESKTOP.md` for the full reverse-engineered architecture.

## Daily usage

In any terminal:

```bash
cowork-skills            # zsh function — runs sync.py
```

Output looks like:
```
cowork-skills sync
  source : /Users/.../.claude/skills
  target : /Users/.../rpm/plugin_claude-code-skills-bridge/skills

  + bitwarden-expert               (5 files)
  + browser-expert                 (2 files)
  ...

Excluded (already bundled by Cowork): docx, pdf, pptx, skill-creator, xlsx

Synced 15 skills, 47 files total.
Next step:
  Restart Claude Desktop.
  Inside Cowork, your skills appear as 'claude-code-skills-bridge:<name>'.
```

After restarting Claude Desktop, open a new Cowork session and you'll see the skills auto-discoverable under their `claude-code-skills-bridge:` prefix.

## What gets filtered

- Skills with the same name as Cowork's bundled `anthropic-skills`: `docx`, `pdf`, `pptx`, `xlsx`, `skill-creator`, `schedule`, `setup-cowork`, `consolidate-memory`
- Symlinks pointing **into** Cowork's own skills-plugin directory
- Dotfiles (anything starting with `.`)
- Directories without a `SKILL.md`

## Install (one-time)

```bash
~/.config/cowork-skills/install.sh
```

That does:
1. Copies the plugin from your dotfiles tree into Cowork's `rpm/plugin_claude-code-skills-bridge/`.
2. Registers the plugin in `rpm/manifest.json` (under `marketplace_local` / "My Uploads").
3. Runs the initial `sync.py` to populate `skills/` from `~/.claude/skills/`.
4. Tells you to restart Claude Desktop.

Idempotent: safe to re-run if you change the plugin manifest or want a clean re-install.

## Environment variables

| Var | Default | Effect |
|---|---|---|
| `COWORK_SKILLS_DIR` | `~/.claude/skills` | Source directory |

The sync target (the installed plugin path) is auto-discovered under `~/Library/Application Support/Claude/local-agent-mode-sessions/<user>/<plugin>/rpm/plugin_claude-code-skills-bridge/skills/`.

## Caveats

- Some skills assume host-only tools (e.g., `bw-fetch`) or host paths (`/Users/raphael/...`). Inside Cowork's VM those won't resolve — adapt as needed or expect graceful failure.
- The sync wipes and rebuilds the plugin's `skills/` each run. Skills you remove from `~/.claude/skills/` will also be removed from Cowork on the next sync.
- New skills require a Claude Desktop restart to appear in Cowork (the VM snapshots plugin state at session boot).
