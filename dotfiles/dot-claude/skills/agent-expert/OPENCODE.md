# OpenCode Reference

OpenCode is a 100% open-source (MIT) AI coding agent harness built by Anomaly Co., founded by Anthropic alumni. It is provider-agnostic, TUI-first, and designed by the neovim users and terminal.shop team. Its client/server architecture allows remote control of the agent. It ships with out-of-the-box LSP support for language-aware editing.

---

## Table of Contents

1. [Architecture](#architecture)
2. [Agent System](#agent-system)
3. [Provider Support](#provider-support)
4. [Tool System](#tool-system)
5. [Skills System](#skills-system)
6. [Permission System](#permission-system)
7. [Configuration](#configuration)
8. [.opencode Directory](#opencode-directory)
9. [Session Management](#session-management)
10. [AGENTS.md](#agentsmd)
11. [MCP Support](#mcp-support)
12. [Key Commands](#key-commands)
13. [Installation](#installation)

---

## Architecture

OpenCode is a monorepo using Bun as the package manager.

### Key Packages

| Package | Purpose |
|---------|---------|
| `opencode` | Core agent runtime |
| `sdk/js` | JavaScript/TypeScript SDK |
| `server` | HTTP server for client/server mode |
| `plugin` | Plugin SDK for custom tools |
| `shared` | Shared types and utilities |
| `console` | CLI entry point |
| `desktop` | Tauri-based desktop app |
| `web` | Web interface |
| `ui` | Shared UI components |
| `extensions` | Editor extensions |

### Core Technologies

| Layer | Technology |
|-------|-----------|
| Runtime | TypeScript, Bun |
| Effect management | Effect.js |
| HTTP server | Hono |
| Database | SQLite via Drizzle ORM |
| Schema validation | Zod |
| AI providers | Vercel AI SDK |
| Syntax parsing | Tree-sitter |
| File search | ripgrep |

The client/server split enables remote control: the server exposes an HTTP API, and TUI or other clients connect to it. This means multiple frontends (TUI, web, desktop) can attach to the same running agent session.

---

## Agent System

OpenCode ships with several built-in agents and supports fully custom agents.

### Built-in Agents

| Agent | Type | Mode | Tools Available |
|-------|------|------|-----------------|
| `build` | Primary | Full access | All tools |
| `plan` | Primary | Read-heavy | Restricted (no writes) |
| `general` | Subagent | Full tools, parallel | Complex multi-step tasks |
| `explore` | Subagent | Read-only, fast | Glob, Grep, Read only |
| `compaction` | Hidden | Internal | Context summarization |
| `title` | Hidden | Internal | Session title generation |
| `summary` | Hidden | Internal | Session summary generation |

- **Primary agents** are user-facing and selectable via Tab.
- **Subagents** are spawned by primary agents to parallelize work.
- **Hidden agents** run automatically as internal infrastructure.

### Custom Agents

Custom agents are markdown files with YAML frontmatter. They can live in:
- `.opencode/agents/<name>.md` — project-scoped
- `~/.config/opencode/agents/<name>.md` — user-global

#### Agent Frontmatter Schema

```yaml
---
name: my-agent
description: What this agent does and when to use it
mode: build          # build | plan
model: claude-3-5-sonnet-20241022
prompt: ./prompts/my-agent.md   # or inline prompt text
temperature: 0.3
top_p: 0.9
steps: 50            # max iterations per session
color: "#ff6600"
hidden: false
disable: false
permissions:
  read: { "*": "allow" }
  edit: { "src/**": "allow", "*": "deny" }
  bash: "ask"
---

Agent description and instructions go here (markdown body is the system prompt).
```

#### Agent Config Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique identifier |
| `description` | string | Shown in agent picker |
| `mode` | `build` \| `plan` | Base capability set |
| `model` | string | Override default model |
| `prompt` | string | File path or inline prompt |
| `temperature` | float | Sampling temperature |
| `top_p` | float | Nucleus sampling |
| `steps` | integer | Max tool-call iterations |
| `permissions` | object | Per-tool permission rules |
| `color` | hex string | TUI display color |
| `hidden` | boolean | Hide from agent picker |
| `disable` | boolean | Fully disable the agent |

---

## Provider Support

OpenCode supports 75+ providers via the Vercel AI SDK.

### Major Cloud Providers

| Provider | Notes |
|----------|-------|
| Anthropic | Interleaved thinking support |
| OpenAI | GPT-4.5, Responses API |
| Google Generative AI | Gemini models |
| Google Vertex AI | Enterprise Vertex endpoint |
| Amazon Bedrock | Multi-region support |
| Azure OpenAI | Enterprise Azure endpoint |
| OpenRouter | Meta-router for many providers |
| Mistral | |
| Groq | |
| DeepInfra | |
| Cerebras | |
| Cohere | |
| Together AI | |
| Perplexity | |
| xAI | Grok models |
| Venice AI | |
| Alibaba | Qwen models |
| GitLab | GitLab AI features |
| GitHub Copilot | |

### Local Providers

| Provider | Notes |
|----------|-------|
| Ollama | Local model server |
| llama.cpp | Direct llama.cpp server |
| LM Studio | GUI-based local models |

### Proprietary OpenCode Plans

| Plan | Description |
|------|-------------|
| OpenCode Zen | Curated model selection, managed by Anomaly Co. |
| OpenCode Go | Low-cost subscription tier |

### Custom Providers

Any OpenAI-compatible API can be added via `@ai-sdk/openai-compatible`:

```jsonc
{
  "provider": {
    "my-provider": {
      "options": {
        "baseURL": "https://api.example.com/v1",
        "headers": {
          "X-Custom-Header": "value"
        }
      },
      "env": ["MY_PROVIDER_API_KEY"]
    }
  }
}
```

---

## Tool System

### Built-in Tools

| Tool | Description |
|------|-------------|
| `bash` | Execute shell commands |
| `read` | Read file contents |
| `write` | Write files to disk |
| `edit` | Make targeted edits to files |
| `apply_patch` | Apply unified diffs |
| `glob` | Pattern-based file search |
| `grep` | Content search via ripgrep |
| `list` | List directory contents (ls) |
| `webfetch` | Fetch a URL |
| `websearch` | Web search via Exa AI |
| `question` | Ask the user a clarifying question |
| `todowrite` | Write structured TODO lists |
| `lsp` | LSP operations (experimental) |
| `skill` | Load and use a skill |
| `task` | Spawn a subagent task |
| `todo` | Read/manage TODO state |
| `multiedit` | Edit multiple files in one call |
| `external-directory` | Access directories outside the project |

### Custom Tools

Custom tools are TypeScript/JavaScript files using `tool()` from `@opencode-ai/plugin`.

**Locations:**
- `.opencode/tools/<name>.ts` — project-scoped
- `~/.config/opencode/tools/<name>.ts` — user-global

**API:**

```typescript
import { tool } from "@opencode-ai/plugin";
import { z } from "zod";

export default tool("my-tool", {
  description: "What this tool does and when to use it",
  parameters: z.object({
    input: z.string().describe("The input to process"),
    verbose: z.boolean().optional().default(false),
  }),
  execute: async (args, ctx) => {
    const result = await doWork(args.input, args.verbose);
    return {
      title: "My Tool Result",
      output: result,
    };
  },
});
```

**Notes:**
- Custom tools can override built-in tools by using the same name.
- Multiple tools can be exported from a single file.
- The `ctx` parameter provides access to session context and config.

---

## Skills System

Skills are markdown documents (similar to Claude Code's SKILL.md) that provide agent instructions or domain knowledge.

### Search Locations (in priority order)

| Location | Scope |
|----------|-------|
| `.opencode/skills/<name>/SKILL.md` | Project-local |
| `~/.config/opencode/skills/<name>/SKILL.md` | User-global |
| `.claude/skills/<name>/SKILL.md` | Claude Code compatible |
| `~/.claude/skills/<name>/SKILL.md` | Claude Code compatible |
| `.agents/skills/<name>/SKILL.md` | Agent-generic |
| `~/.agents/skills/<name>/SKILL.md` | Agent-generic global |

OpenCode is compatible with Claude Code skills — any skill that works in Claude Code will work in OpenCode without modification.

### Skill Frontmatter

Skills require YAML frontmatter with at minimum `name` and `description`:

```yaml
---
name: my-skill
description: What this skill does and when to auto-load it
permissions:
  read: { "*": "allow" }
  bash: "deny"
---
```

Permissions in the frontmatter restrict what the agent can do while using the skill.

---

## Permission System

OpenCode uses a three-state permission model for every tool.

### Permission States

| State | Meaning |
|-------|---------|
| `allow` | Runs without user approval |
| `deny` | Blocked unconditionally |
| `ask` | Prompts user before running |

### Granular Rules

Permissions support glob patterns for fine-grained control:

```jsonc
{
  "permission": {
    "read": {
      "*": "allow",
      "*.env": "ask",
      "**/.ssh/*": "deny"
    },
    "edit": {
      "*": "deny",
      "src/**/*.ts": "allow",
      "tests/**": "allow"
    },
    "write": "ask",
    "bash": "allow",
    "external_directory": {
      "*": "ask",
      "/safe/read-only/path": "allow"
    }
  }
}
```

### Bash Command Patterns

Bash permissions can match against the command string, not just the tool name:

```jsonc
{
  "permission": {
    "bash": {
      "*": "allow",
      "rm *": "ask",
      "rm -rf *": "deny",
      "git *": "ask",
      "git status": "allow",
      "git log*": "allow"
    }
  }
}
```

### Task Permissions

The `task` permission controls whether subagents can be spawned:

```jsonc
{
  "permission": {
    "task": {
      "*": "ask",
      "explore": "allow"
    }
  }
}
```

### Default Permissions by Agent

| Agent | Default Behavior |
|-------|----------------|
| `build` | Full access; prompts user for destructive ops |
| `plan` | Read-only; denies all edits and writes |
| `explore` | Limited to grep, glob, read, webfetch |

---

## Configuration

OpenCode uses a hierarchical configuration system. Higher entries in the list take precedence.

### Hierarchy (highest to lowest priority)

1. **Managed Preferences** — macOS MDM / plist (enterprise deployments)
2. **User Global Config** — `~/.config/opencode/opencode.jsonc`
3. **Project-local Config** — `.opencode/opencode.jsonc`

### Full Config Structure

```jsonc
{
  // Provider configuration
  "provider": {
    "<provider-id>": {
      "options": {
        "baseURL": "https://...",  // for custom providers
        "headers": {}
      },
      "env": ["API_KEY_ENV_VAR"]
    }
  },

  // Permission rules (see Permission System section)
  "permission": {
    "read": { "*": "allow" },
    "edit": { "*": "ask" },
    "bash": "allow"
  },

  // Agent overrides
  "agent": {
    "<agent-name>": {
      "model": "claude-3-5-sonnet-20241022",
      "temperature": 0.2,
      "prompt": "./prompts/custom.md",
      "steps": 100
    }
  },

  // MCP server definitions
  "mcp": {
    "<server-name>": {
      "type": "stdio",
      "command": "node",
      "args": ["path/to/server.js"],
      "env": {}
    }
  },

  // Custom commands
  "commands": {
    "<command-name>": {
      "description": "...",
      "prompt": "..."
    }
  },

  // Additional skill paths
  "skills": {
    "paths": ["/extra/skills/dir"],
    "urls": ["https://example.com/skill.md"]
  },

  // Keybind overrides
  "keybinds": {},

  // TUI display options
  "tui": {}
}
```

### XDG Base Directories

| Purpose | Path |
|---------|------|
| Config | `~/.config/opencode/` |
| Data (DB, sessions) | `~/.local/share/opencode/` |
| Cache | `~/.cache/opencode/` |

---

## .opencode Directory

The `.opencode/` directory in a project root is the primary customization point for project-level OpenCode behavior.

```
.opencode/
├── opencode.jsonc        # Main project config
├── tui.json              # TUI layout and state
├── agent/                # Custom agent definitions (*.md with YAML frontmatter)
│   └── my-agent.md
├── command/              # Custom slash commands (*.md)
│   └── deploy.md
├── skills/               # Project-scoped skills
│   └── my-skill/
│       └── SKILL.md
├── plugins/              # Plugin configuration
├── tool/                 # Custom tool definitions (*.ts or *.js)
│   └── my-tool.ts
├── themes/               # Custom TUI themes
└── glossary/             # Multi-language glossaries for domain terms
```

---

## Session Management

Sessions are persisted to a SQLite database at `~/.local/share/opencode/opencode.db`, managed via Drizzle ORM with schema migrations.

### Session Properties

| Property | Type | Description |
|----------|------|-------------|
| `id` | string | Unique session identifier |
| `slug` | string | Human-readable short name |
| `projectID` | string | Project this session belongs to |
| `directory` | string | Working directory |
| `parentID` | string | Parent session (for branching) |
| `title` | string | Auto-generated or user-set title |
| `version` | integer | Schema version |
| `summary` | string | Auto-generated session summary |
| `share` | boolean | Whether session is publicly shared |
| `permission` | object | Session-level permission overrides |

### Change Management

- `/undo` — revert the last file change made by the agent
- `/redo` — reapply a reverted change
- `/share` — create a public shareable link to the session
- Sessions support branching via `parentID` for exploratory work

---

## AGENTS.md

`AGENTS.md` is the project instructions file for OpenCode, analogous to Claude Code's `CLAUDE.md`.

- Loaded automatically from the project root when a session starts
- Contains project context, conventions, and agent behavior guidelines
- Plain markdown; no frontmatter required
- Can reference other files relative to the project root

Example:

```markdown
# Project Instructions

This is a TypeScript monorepo using Bun.

## Conventions
- All new files must have JSDoc headers
- Tests live in `tests/` colocated with source
- Never modify `dist/` — it is generated

## Build Commands
- `bun run build` — compile TypeScript
- `bun test` — run test suite
- `bun run lint` — ESLint + Prettier
```

---

## MCP Support

OpenCode has native MCP (Model Context Protocol) integration.

### Transport Types

| Type | Description |
|------|-------------|
| `stdio` | Local process via stdin/stdout |
| `http` | Remote HTTP server |
| `sse` | Remote server-sent events |

### Configuration

```jsonc
{
  "mcp": {
    "filesystem": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"],
      "env": {}
    },
    "remote-server": {
      "type": "http",
      "url": "https://mcp.example.com/endpoint",
      "headers": {
        "Authorization": "Bearer ${MCP_TOKEN}"
      }
    }
  }
}
```

### Features

- OAuth support with dynamic client registration
- Tool conversion: MCP tool schemas are translated to Vercel AI SDK format automatically
- Resource access: MCP resources appear as readable context
- Prompt caching: compatible with provider-level prompt caching
- Multiple servers: any number of MCP servers can be configured simultaneously

---

## Key Commands

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `Tab` | Switch between Build and Plan agents |
| `Ctrl+C` | Cancel current agent action |
| `Ctrl+L` | Clear screen |

### Slash Commands

| Command | Description |
|---------|-------------|
| `/share` | Create a public shareable link to the current session |
| `/undo` | Revert the last file change |
| `/redo` | Reapply a reverted change |
| `/connect` | Interactive provider and model setup wizard |

### Image Input

Images can be uploaded by dragging a file directly into the terminal. Supported by providers with vision capabilities.

---

## Installation

OpenCode can be installed via multiple methods:

| Method | Command |
|--------|---------|
| curl script | `curl -fsSL https://opencode.ai/install | sh` |
| npm | `npm install -g opencode-ai` |
| bun | `bun add -g opencode-ai` |
| pnpm | `pnpm add -g opencode-ai` |
| yarn | `yarn global add opencode-ai` |
| Homebrew (macOS) | `brew install opencode-ai/tap/opencode` |
| pacman (Arch) | `pacman -S opencode` |
| Chocolatey (Windows) | `choco install opencode` |
| Scoop (Windows) | `scoop install opencode` |
| Mise | `mise use -g opencode-ai` |
| Docker | `docker run -it ghcr.io/opencode-ai/opencode` |

After installation, run `opencode` in any project directory. On first run, use `/connect` to configure your AI provider.
