# Claude Desktop App

Reference for Claude Desktop application features and capabilities — with deep architectural notes on **Cowork mode** that are not documented anywhere else and that Claude consistently forgets between sessions.

## TL;DR for future-you

If you remember nothing else: **Cowork runs each session inside a real macOS Virtualization.framework VM**. The VM mounts only the installed plugin tree — it cannot see your home directory. `~/.claude/skills/` does not exist inside it. Symlinks pointing outside the plugin tree do not resolve. Cowork's plugin `.mcp.json` accepts **only HTTP MCP servers** (no stdio). These constraints are non-negotiable.

## Overview

Claude Desktop is the native macOS/Windows app for interacting with Claude. It extends claude.ai with:
- Native chat with file/image uploads, artifacts pane, Projects
- MCP servers (stdio) registered in `~/Library/Application Support/Claude/claude_desktop_config.json`
- **Cowork mode** — persistent, sandboxed Claude Code-like sessions running in a VM
- Scheduled tasks (recurring prompts)
- Claude Design / Claude for Creative Work (Anthropic Labs, 2026)

## Regular Desktop chat vs. Cowork mode

| Feature | Regular Desktop chat | Cowork mode |
|---|---|---|
| Execution environment | Host (the Desktop app process) | VM (Virtualization.framework + gvisor) |
| Filesystem access | Drag-and-drop uploads only | Full read/write inside session work dir |
| MCP servers | Top-level `claude_desktop_config.json`, **stdio + http both supported** | Plugin-bundled `.mcp.json`, **HTTP only** |
| Skill primitive | None | Yes — uses Claude Code's SKILL.md format |
| Persistence | Per-conversation, host-stored | Per-session, sandboxed inside VM |

The two surfaces share the same Desktop app process but have completely separate plugin/MCP systems. Configuration that works in one usually does not apply to the other.

## Cowork mode — full architectural breakdown

Cowork is a Claude Code instance running inside a sandboxed VM that the Desktop app boots when you open a Cowork session. The VM is built on Apple's `Virtualization.framework` plus `gvisor` for syscall sandboxing.

### Host-side paths (everything below is on the macOS host)

```
~/Library/Application Support/Claude/
├── claude_desktop_config.json          # Regular Desktop chat MCP config (stdio OK)
│
├── claude-code-vm/<version>/           # Cowork's Claude Code binary
├── vm_bundles/
│   └── claudevm.bundle/                # The VM image — boot it to get a Cowork session
│       ├── rootfs.img                  # Base OS image (shared across sessions)
│       ├── sessiondata.img             # Per-session writable disk image
│       ├── machineIdentifier, macAddress, gvisorMacAddress, vmIP
│       └── efivars.fd
│
└── local-agent-mode-sessions/          # Cowork state lives here
    │
    ├── skills-plugin/<plugin_uuid>/<user_uuid>/    # The built-in "anthropic-skills" plugin
    │   ├── .claude-plugin/plugin.json              # { name: "anthropic-skills", version }
    │   ├── manifest.json                           # Skill registry (skillId, name, description, enabled)
    │   └── skills/<skill-name>/SKILL.md            # docx, pdf, pptx, xlsx, skill-creator,
    │                                               # schedule, setup-cowork, consolidate-memory
    │
    └── <user_uuid>/<plugin_uuid>/                  # Per-user/plugin state (one user_uuid per
        │                                           # Anthropic account; plugin_uuid is the
        │                                           # plugin manager's instance)
        │
        ├── .project-cache/, .claude.json.lock      # Project + lock metadata
        ├── debug/                                  # Debug logs
        │
        ├── local_<session_uuid>/                   # One directory per Cowork session
        │   ├── .claude/                            # Per-session Claude Code state
        │   │   ├── projects/, plans/, todos/,
        │   │   │   debug/, shell-snapshots/,
        │   │   │   session-env/, backups/
        │   │   ├── .claude.json                    # Session config
        │   │   ├── .credentials.json               # Session creds
        │   │   └── mcp-needs-auth-cache.json
        │   ├── outputs/                            # Files Claude produced
        │   ├── uploads/                            # Files the user dragged in
        │   └── audit.jsonl                         # Full session audit log
        │
        ├── cowork_plugins/                         # Plugin manager state (one place)
        │   ├── installed_plugins.json              # Registry of installed plugins
        │   ├── known_marketplaces.json             # GitHub repos serving as marketplaces
        │   ├── marketplaces/                       # Cloned marketplace repos
        │   ├── cache/<marketplace>/<plugin>/<ver>/ # Marketplace-installed plugins live here
        │   └── .install-manifests/<plugin>.json    # SHA-256 per-file integrity manifests
        │
        └── rpm/plugin_<ksuid>/                     # Alternate plugin install path used by
            │                                       # third-party marketplaces (e.g.,
            │                                       # agentskill.sh). Side-by-side with
            │                                       # cowork_plugins/cache/, no shared registry.
            ├── .claude-plugin/plugin.json
            ├── skills/<name>/SKILL.md
            ├── commands/<name>.md
            └── .mcp.json                           # Optional MCP servers for this plugin
```

The user-facing `local_<session_uuid>/.claude/` is what the Cowork agent inside the VM treats as its home. Per-session `.credentials.json`, project state, todos, and plans live there — isolated per session.

### What gets mounted into the VM

When Cowork boots a VM session, only the **installed plugin trees** (both `cowork_plugins/cache/.../<version>/` and `rpm/plugin_*/`) plus the built-in `skills-plugin/` are exposed to the VM. The VM does **not** see:
- `~/.claude/skills/` (your Claude Code skills)
- `~/.claude/agents/`, `~/.claude/commands/` (your Claude Code agents/commands)
- The top-level `claude_desktop_config.json` MCP servers
- Any arbitrary host path

Symlinks pointing **outside** the mounted plugin tree do not resolve inside the VM — the path target literally does not exist. The existing third-party plugins (e.g., `agentskill-learn` under `rpm/`) all contain **physical files, not symlinks**, for this reason.

### Plugin install paths — two parallel systems

| Path | Source | Registry | Integrity check |
|---|---|---|---|
| `cowork_plugins/cache/<marketplace>/<plugin>/<version>/` | GitHub marketplace repo (e.g., `anthropics/knowledge-work-plugins`) | `cowork_plugins/installed_plugins.json` | `cowork_plugins/.install-manifests/<plugin>.json` (SHA-256 per file) |
| `rpm/plugin_<ksuid>/` | Third-party marketplaces (e.g., `agentskill.sh`) | No central registry alongside | Not centrally tracked |

A plugin can live in either path; both are scanned when the VM mounts plugins for a session. The `cowork_plugins/` path is the "official" route (used by Cowork's own UI when you click "Install" on an `anthropics/...` marketplace plugin). The `rpm/` path is used by some third-party marketplaces and as the install target for community plugins.

### Plugin structure (same as Claude Code plugins)

```
<plugin-dir>/
├── .claude-plugin/
│   └── plugin.json         # { name, version, description, author? }
├── .mcp.json               # Optional — MCP servers for this plugin (HTTP ONLY in Cowork)
├── skills/<name>/SKILL.md  # Optional — skills
├── commands/<name>.md      # Optional — slash commands
├── agents/<name>.md        # Optional — sub-agent definitions
├── hooks/                  # Optional
└── README.md
```

This is byte-for-byte the same plugin format Claude Code uses (`.claude-plugin/plugin.json` + `skills/`, etc.). Plugins written for one work in the other — except for the MCP-transport difference noted below.

### Built-in skills (the `anthropic-skills` plugin)

Cowork ships with these always-available skills, sourced from the `skills-plugin/<plugin_uuid>/<user_uuid>/` tree:

| Skill | Description |
|---|---|
| `docx` | Word document creation, parsing, editing |
| `xlsx` | Excel spreadsheet operations |
| `pptx` | PowerPoint slide creation/editing |
| `pdf` | PDF text/table extraction, generation, forms |
| `skill-creator` | Create new skills, run evals on existing ones |
| `schedule` | Create a scheduled task (on demand or on interval) |
| `setup-cowork` | Guided Cowork onboarding (install plugins, connect tools) |
| `consolidate-memory` | Reflective pass over memory files |

These are listed in `skills-plugin/.../manifest.json` with `creatorType: "anthropic"` and an `enabled: true` flag.

### MCP integration — DON'T declare your own HTTP MCP in a third-party plugin

**Critical and counter-intuitive**: looking at bundled Cowork plugins (`enterprise-search`, `productivity`, `product-management`) shows every `.mcp.json` uses `"type": "http"` with HTTPS URLs to `mcp.slack.com`, `mcp.linear.app`, `mcp.atlassian.com`, etc. This suggests Cowork supports HTTP MCP servers from plugins. **It doesn't, for third-party plugins.**

Cowork's host process **shadows plugin-declared remote MCP servers with no-ops**. The smoking-gun line in `~/Library/Logs/Claude/main.log`:

```
[info] Plugin "plugin_<your-plugin>" has remote MCP servers (<your-mcp>).
Shadowing with no-ops to prevent SDK double-load.
```

What's happening:
- Cowork loads a fixed set of MCP servers itself via its built-in SDK (mcp.slack.com, mcp.linear.app, etc.). These are advertised under names like `plugin:engineering:slack`, `plugin:product-management:figma`.
- When a plugin's `.mcp.json` references one of those URLs, Cowork's host code is already the one running it — so the plugin's declaration is shadowed to a no-op stub to prevent double-load.
- For URLs Cowork's SDK doesn't know about (e.g., your `http://192.168.64.1:8765/mcp`), the **same shadowing applies** anyway. The MCP entry shows up in the session's `mcp_servers` list with status `connected`, but the actual server has been replaced — tool calls return nothing.

**Conclusion**: you cannot bridge your own HTTP MCP server into a Cowork session via a third-party plugin. The only MCP endpoints that work are the ones Cowork's host process has pre-built support for.

Stdio MCP entries in the top-level `claude_desktop_config.json` are for the host-side regular Desktop chat process and are not visible to the Cowork VM at all.

### How Cowork actually loads third-party plugin skills

For plugin skills (no MCP), the path is straightforward and works. The cowork daemon (`coworkd`) spawns `claude` inside the VM with multiple `--plugin-dir` arguments — one per installed plugin. Example from `~/Library/Logs/Claude/coworkd.log`:

```
spawn: cmd=/usr/local/bin/claude args=[
  ...
  --plugin-dir /sessions/<session-name>/mnt/.local-plugins/cache/knowledge-work-plugins/enterprise-search/1.0.0
  --plugin-dir /sessions/<session-name>/mnt/.local-plugins/cache/knowledge-work-plugins/productivity/1.0.0
  --plugin-dir /sessions/<session-name>/mnt/.remote-plugins/plugin_<your-plugin>
  ...
]
```

`.local-plugins/cache/<marketplace>/<plugin>/<version>/` is mounted from the host's `cowork_plugins/cache/...`. `.remote-plugins/plugin_<ksuid>/` is mounted from the host's `rpm/plugin_<ksuid>/`. Claude inside the VM scans each `--plugin-dir/skills/<name>/SKILL.md` and auto-discovers them by description, exactly the same as Claude Code. Skills appear in Cowork as `<plugin-name>:<skill-name>` (e.g., `engineering:code-review`).

**This is the working extension path**: drop real-file skills into your plugin's `skills/` directory. No host server, no port, no network.

### VM networking — gvisor netstack, not vmnet

The VM uses **gvisor's userspace network stack** with an IP from `172.16.10.0/24` (recorded in `vm_bundles/claudevm.bundle/vmIP`). There is **no `bridge100` interface** on the host — Apple-vmnet's typical `192.168.64.1` gateway address is wrong for Cowork. The VM does have outbound internet for fetching Anthropic-hosted MCP endpoints, but reaching a server bound to the host's loopback or LAN IP from inside the VM is not part of the supported model.

Inside a Cowork session, ask Claude:
```bash
ip route show default
hostname -I
```
to see the VM's address. Outbound HTTPS to public endpoints works; inbound to a user-run host server does not (and would be shadowed by Cowork's MCP loader even if it did).

## Scheduled Tasks

Schedule prompts to run automatically on a recurring cadence. Useful for recurring reports, monitoring runs, periodic data refreshes. Desktop-only; Claude Code has `/loop` and `/schedule` skills for similar effects.

Toggled by:
- `coworkScheduledTasksEnabled: true` (top-level preferences)
- `ccdScheduledTasksEnabled: true` (Claude Code Desktop variant)

## Claude Desktop preferences (top-level `claude_desktop_config.json`)

Notable preference keys observed in production configs:

| Key | Effect |
|---|---|
| `localAgentModeTrustedFolders` | Whitelisted directories Cowork sessions may mount |
| `coworkScheduledTasksEnabled` | Enables scheduled tasks for Cowork sessions |
| `ccdScheduledTasksEnabled` | Enables scheduled tasks for the CCD variant |
| `sidebarMode` | UI mode ("task", "chat", etc.) |
| `bypassPermissionsModeEnabled` | Skips most permission prompts in Cowork |
| `coworkWebSearchEnabled` | Cowork's built-in web search |
| `keepAwakeEnabled` | Prevents macOS sleep while Cowork sessions run |
| `epitaxyPrefs.starred-cowork-spaces` | Starred/pinned Cowork sessions in the sidebar |

## Recent Anthropic announcements

| Date | Announcement | Notes |
|---|---|---|
| 2026-04-16 | Claude Opus 4.7 released | Stronger coding, agents, vision, multi-step. Model ID `claude-opus-4-7` |
| 2026-04-17 | Claude Design (Anthropic Labs) | Visual creation: designs, prototypes, slides |
| 2026-04-28 | Claude for Creative Work | Expanded creative-application capabilities |
| 2026-05-05 | Agents for financial services | Specialized agent offering |
| 2026-05-06 | Higher usage limits | Increased for subscribers |
| 2026-05-06 | SpaceX compute deal | Compute infrastructure partnership |
| 2026-05-28 | Claude Opus 4.8 released | Enhanced agentic tasks, defaults to xhigh effort. Fast mode at 2x rate. Model ID `claude-opus-4-8` ($5/$25 per MTok) |
| 2026-06-09 | Claude Fable 5 & Mythos 5 released | Mythos-class frontier intelligence; Fable 5 is the publicly-available, safety-gated variant. State-of-the-art on nearly all benchmarks; 1M context, 128k output. Model ID `claude-fable-5` ($10/$50 per MTok — the new top tier, 2× Opus). Mythos 5 is limited-availability via Project Glasswing. Requires Claude Code v2.1.170+ |

## Sources

- Download: https://www.anthropic.com/download
- News: https://www.anthropic.com/news
- Support: https://support.claude.com/en/collections/4560928-claude-desktop
- Cowork architectural facts above are reverse-engineered from `~/Library/Application Support/Claude/` and the bundled plugins under `local-agent-mode-sessions/skills-plugin/` — not officially documented; verify on your own machine before relying on them.

## Common forgetting traps (read before designing anything for Cowork)

1. **"Just symlink ~/.claude/skills/ into the plugin."** — Doesn't work. The VM only sees what's physically inside the mounted plugin tree. Symlinks pointing outside resolve to nonexistent host paths from the VM's perspective. Copy real files instead (`cp -RL` or equivalent).
2. **"Just register an MCP server in claude_desktop_config.json."** — That config is for regular Desktop chat. Cowork ignores it.
3. **"Plugins can declare their own HTTP MCP server in .mcp.json."** — They *appear* to, but Cowork **shadows third-party plugin-declared MCP servers with no-ops** (`Shadowing with no-ops to prevent SDK double-load`). Only Cowork's pre-built SDK MCPs (slack/notion/linear/etc.) actually function. Running your own HTTP MCP server on the host and pointing a plugin's `.mcp.json` at it will report `status: connected` but tool calls return nothing.
4. **"Bind the host HTTP server to 0.0.0.0 so the VM can reach it."** — Moot. Even if the VM could reach it (it can't reliably under gvisor netstack at `172.16.10.0/24`), Cowork's shadowing kicks in first.
5. **"Cowork shares the host's filesystem."** — It doesn't. Each session has its own `local_<uuid>/` work directory; outside that and the plugin tree, the VM sees nothing.
6. **"Plugins auto-discover skills from ~/.claude/skills/ at boot."** — They don't. Each plugin's `skills/` directory is exactly what becomes available inside the VM. No external discovery.
7. **"The host's `~/.claude/skills/` mounts into the VM."** — No. The `mounts=...,.claude/skills,...` you see in the workspace MCP logs is Cowork's bundled `anthropic-skills` plugin (read-only), not your user skills tree.
8. **"The VM gateway is 192.168.64.1."** — That's the Apple-vmnet default but Cowork uses gvisor's netstack on `172.16.10.x` and does not surface a bridge interface on the host. The host is not reliably reachable from inside.

### The only working extension path for third-party skills in Cowork

Drop **real files** into your plugin's `skills/<name>/SKILL.md` tree, register the plugin under `rpm/plugin_<id>/` and `rpm/manifest.json`, restart Claude Desktop. The skills appear inside Cowork as `<plugin-name>:<skill-name>`, auto-discovered by description. See the `cowork-skills` tool in `dotfiles/dot-config/cowork-skills/` for a working implementation that syncs `~/.claude/skills/` into the `claude-code-skills-bridge` plugin.
