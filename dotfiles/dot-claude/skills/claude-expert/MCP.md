# MCP (Model Context Protocol) Reference

## What Is MCP?

MCP (Model Context Protocol) is a standard for connecting AI assistants to external tools and data sources. MCP servers provide:
- **Tools**: Functions Claude can call (e.g., search, API calls)
- **Resources**: Data Claude can access (e.g., files, databases)
- **Prompts**: Pre-defined prompt templates

## Configuration Scopes

MCP servers can be configured at multiple levels (in precedence order):

| Scope | Location | Use Case |
|-------|----------|----------|
| Local (default) | `~/.claude.json` under project path | Personal, single project |
| Project | `.mcp.json` in project root | Shared via git, team use |
| User | `~/.claude.json` | Cross-project, personal |
| Managed | `managed-mcp.json` (system dir) | Enterprise, admin-controlled |

### Scope Hierarchy and Precedence

When the same server is defined in more than one place, Claude Code connects to it once, using the entire definition from the highest-precedence source (fields are never merged across scopes):

1. Local scope
2. Project scope
3. User scope
4. Plugin-provided servers
5. claude.ai connectors
6. Managed MCP servers (`managedMcpServers`, requires v2.1.259+ — see below)

Local/project/user scopes match duplicates by **name**; plugins and claude.ai connectors match by **endpoint** (same URL or command counts as a duplicate).

### `managedMcpServers` — Organization-Wide HTTP/SSE Servers (v2.1.259+)

Organizations can push MCP servers to every user through managed settings, using the same entry shape as `.mcp.json`:

```json
{
  "managedMcpServers": {
    "company-api": {
      "type": "http",
      "url": "https://mcp.company.com",
      "headers": { "Authorization": "Bearer ${COMPANY_API_TOKEN}" }
    }
  }
}
```

Entries that name a command to run (stdio) are skipped — only HTTP/SSE servers are supported here. `managedMcpServers` sits at the **bottom** of the precedence order above, so a user's local/project/user-scope server, a plugin server, or a claude.ai connector with the same name wins over it. `allowedMcpServers` governs only servers users add themselves — as of v2.1.259, it no longer filters out a literal `managedMcpServers` entry; use `deniedMcpServers` to keep a managed server off instead.

**Project server approvals & workspace trust (v2.1.196+)**: `claude mcp list`/`claude mcp get` only read `.mcp.json` approvals from settings files that aren't checked into the repo, until you trust the workspace. A freshly cloned repo can't self-approve its own `.mcp.json` servers via a committed `enableAllProjectMcpServers`/`enabledMcpjsonServers` — they stay `⏸ Pending approval` until you run `claude` interactively and accept the trust dialog. Approvals from `~/.claude/settings.json`, managed settings, or `--settings` still apply in an untrusted folder. `claude -p`, Agent SDK runs, and cloud sessions can't show the approval prompt at all, so they load project-scoped servers without asking (unless `disabledMcpjsonServers` blocks them, or `--setting-sources`/`settingSources` excludes project settings).

**Note**: Scope names changed: "local" was previously "project", "user" was previously "global".

### Basic Configuration
```json
{
  "mcpServers": {
    "server-name": {
      "command": "command-to-run",
      "args": ["arg1", "arg2"]
    }
  }
}
```

### Environment Variable Expansion

Supported in `command`, `args`, `env`, `url`, and `headers` fields:
- `${VAR}` - expand to value of VAR
- `${VAR:-default}` - expand to VAR if set, otherwise use default

```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      },
      "env": {
        "DEBUG": "${DEBUG:-false}"
      }
    }
  }
}
```

## Transport Types

### HTTP (Recommended for Cloud)
Primary transport for cloud-based MCP servers:

```bash
claude mcp add --transport http my-server https://api.example.com/mcp

# With authentication header
claude mcp add --transport http my-server https://api.example.com/mcp \
  --header "Authorization: Bearer your-token"
```

```json
{
  "mcpServers": {
    "my-server": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "headers": {"Authorization": "Bearer token"}
    }
  }
}
```

### OAuth Authentication

For servers requiring OAuth 2.0, use `/mcp` inside Claude Code to authenticate via browser. Tokens are stored securely (system keychain on macOS, credentials file elsewhere) and refreshed automatically.

#### Authenticate From the Command Line (v2.1.186+)

Run a configured server's OAuth flow directly from the shell without opening `/mcp`:

```bash
claude mcp login sentry
claude mcp logout sentry   # clear stored credentials
```

As of v2.1.191, `login` detects when no local browser is available (SSH session, headless Linux) and prints the authorization URL instead of trying to open one — paste the redirect URL back at the prompt (needs an interactive terminal, so use `ssh -t`). Force this with `--no-browser`.

#### OAuth Discovery Chain

By default Claude Code checks RFC 9728 Protected Resource Metadata (`/.well-known/oauth-protected-resource`), then falls back to RFC 8414 authorization server metadata (`/.well-known/oauth-authorization-server`). Override with `oauth.authServerMetadataUrl` in `.mcp.json` to bypass discovery or route through an internal proxy — the URL must be `https://` and its `scopes_supported` overrides server-advertised scopes.

Claude Code also supports servers using a **Client ID Metadata Document (CIMD / SEP-991)** instead of Dynamic Client Registration, and discovers these automatically; fall back to pre-configured credentials only if automatic discovery fails.

#### RFC 9728 Protected Resource Metadata Discovery (v2.1.85+)

OAuth discovery follows RFC 9728 standard. Two env vars help configure multi-server setups:
```bash
CLAUDE_CODE_MCP_SERVER_NAME=my-server
CLAUDE_CODE_MCP_SERVER_URL=https://api.example.com/mcp
```

These variables are used automatically in header helpers during OAuth flows.

### Pre-Configured OAuth (v2.1.30+)

For servers without Dynamic Client Registration, pre-configure OAuth credentials:

```bash
# With CLI flags
claude mcp add --transport http my-server https://api.example.com/mcp \
  --client-id YOUR_CLIENT_ID \
  --client-secret

# With environment variable
MCP_CLIENT_SECRET=your-secret claude mcp add --transport http my-server \
  https://api.example.com/mcp --client-id YOUR_CLIENT_ID --client-secret
```

The `--client-secret` flag prompts for masked input. Use `MCP_CLIENT_SECRET` env var for CI/automation.

### Fixed OAuth Callback Port

Use `--callback-port` to fix the OAuth callback port for servers requiring a specific redirect URI:

```bash
# With dynamic client registration
claude mcp add --transport http --callback-port 8080 my-server https://mcp.example.com/mcp

# With pre-configured credentials
claude mcp add --transport http --client-id YOUR_ID --client-secret --callback-port 8080 my-server https://mcp.example.com/mcp
```

Also supported in JSON config:
```json
{
  "mcpServers": {
    "my-server": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "oauth": {
        "clientId": "your-client-id",
        "callbackPort": 8080
      }
    }
  }
}
```

### Custom Auth Server Metadata URL (v2.1.69+)

For servers using non-standard OAuth discovery:
```json
{
  "mcpServers": {
    "my-server": {
      "type": "http",
      "url": "https://api.example.com/mcp",
      "oauth": {
        "authServerMetadataUrl": "https://auth.example.com/.well-known/oauth-authorization-server"
      }
    }
  }
}
```

### stdio (Local Servers)
Server communicates via stdin/stdout:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["/path/to/server.js"]
    }
  }
}
```

### SSE (Deprecated)
Server-Sent Events - use HTTP instead:

```json
{
  "mcpServers": {
    "my-server": {
      "url": "http://localhost:3000/sse"
    }
  }
}
```

### WebSocket (Persistent Bidirectional)

For remote servers that push events to Claude unprompted. Use HTTP instead when the server only responds to requests — WebSocket supports neither OAuth nor `claude mcp add --transport` (add it via `add-json` only):

```bash
claude mcp add-json events-server \
  '{"type":"ws","url":"wss://mcp.example.com/socket","headers":{"Authorization":"Bearer YOUR_TOKEN"}}'
```

`type: "ws"` accepts the same `url`, `headers`, `headersHelper`, `timeout`, and `alwaysLoad` fields as `http`. Authentication is header-only. WebSocket servers don't appear in `claude mcp list` — check them with `claude mcp get <name>` or `/mcp`.

### Common Configuration Errors

A JSON entry with a `url` but no `type` is read as a **stdio** server and is skipped, with the error `MCP server "<name>" has a "url" but no "type"; add "type": "http" (or "sse" / "ws") to this entry` (before v2.1.202: `command: expected string, received undefined`). Always set `type` explicitly for remote servers.

**HTTP servers that only speak legacy HTTP+SSE (v2.1.265 fix)**: a server configured as `"type": "http"` that only supports the older HTTP+SSE transport used to never connect. Claude Code now falls back to SSE automatically when the HTTP handshake indicates the server needs it, as the MCP spec describes — no config change needed.

## Common MCP Servers

### Python (uv)
```json
{
  "mcpServers": {
    "my-python-server": {
      "command": "uv",
      "args": [
        "--directory",
        "/path/to/server",
        "run",
        "server-name"
      ]
    }
  }
}
```

### Node.js (npx)
```json
{
  "mcpServers": {
    "my-node-server": {
      "command": "npx",
      "args": ["-y", "@package/server-name"]
    }
  }
}
```

### Docker
```json
{
  "mcpServers": {
    "my-docker-server": {
      "command": "docker",
      "args": [
        "run",
        "-i",
        "--rm",
        "image-name"
      ]
    }
  }
}
```

## Environment Variables

Pass environment variables to servers:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["/path/to/server.js"],
      "env": {
        "API_KEY": "your-api-key",
        "DEBUG": "true"
      }
    }
  }
}
```

## Complete Examples

### GitHub MCP Server
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "ghp_..."
      }
    }
  }
}
```

### Filesystem Server
```json
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "/path/to/allowed/directory"
      ]
    }
  }
}
```

### Postgres Server
```json
{
  "mcpServers": {
    "postgres": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-postgres"],
      "env": {
        "DATABASE_URL": "postgresql://user:pass@localhost:5432/db"
      }
    }
  }
}
```

### Custom Python Server
```json
{
  "mcpServers": {
    "mcp-ical": {
      "command": "uv",
      "args": [
        "--directory",
        "/Users/raphael/.local/share/mcp-servers/mcp-ical",
        "run",
        "mcp-ical"
      ]
    }
  }
}
```

## Creating an MCP Server

### Python Server (Minimal)

```python
# server.py
from mcp.server import Server
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent

server = Server("my-server")

@server.list_tools()
async def list_tools():
    return [
        Tool(
            name="hello",
            description="Say hello to someone",
            inputSchema={
                "type": "object",
                "properties": {
                    "name": {"type": "string", "description": "Name to greet"}
                },
                "required": ["name"]
            }
        )
    ]

@server.call_tool()
async def call_tool(name: str, arguments: dict):
    if name == "hello":
        return [TextContent(type="text", text=f"Hello, {arguments['name']}!")]
    raise ValueError(f"Unknown tool: {name}")

async def main():
    async with stdio_server() as (read, write):
        await server.run(read, write)

if __name__ == "__main__":
    import asyncio
    asyncio.run(main())
```

### pyproject.toml
```toml
[project]
name = "my-server"
version = "0.1.0"
dependencies = ["mcp>=1.0.0"]

[project.scripts]
my-server = "server:main"
```

### TypeScript Server (Minimal)

```typescript
// server.ts
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";

const server = new Server({
  name: "my-server",
  version: "1.0.0"
}, {
  capabilities: {
    tools: {}
  }
});

server.setRequestHandler("tools/list", async () => ({
  tools: [{
    name: "hello",
    description: "Say hello",
    inputSchema: {
      type: "object",
      properties: {
        name: { type: "string" }
      },
      required: ["name"]
    }
  }]
}));

server.setRequestHandler("tools/call", async (request) => {
  if (request.params.name === "hello") {
    return {
      content: [{
        type: "text",
        text: `Hello, ${request.params.arguments.name}!`
      }]
    };
  }
  throw new Error(`Unknown tool: ${request.params.name}`);
});

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main();
```

## MCP Elicitation (v2.1.76+)

MCP servers can request structured input mid-task using MCP's **elicitation** protocol feature. No configuration is required — dialogs appear automatically when a server requests them:

- **Form mode**: Claude Code shows a dialog with server-defined form fields (e.g. username/password prompt). Fill in and submit.
- **URL mode**: Claude Code opens a browser URL for auth/approval; complete the flow in the browser, then confirm in the CLI.

A call waiting on an open elicitation dialog is never auto-backgrounded — Claude Code treats the server as blocked on your input, not slow, and defers the background-move until the dialog closes.

To auto-respond without showing a dialog, handle it via hooks. Claude Code exposes **`Elicitation`** (fires when a server requests input — a hook can auto-accept/reject/set content instead of prompting the user) and **`ElicitationResult`** (fires after the response is submitted) hook events:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "Elicitation",
    "action": "accept",
    "content": { "username": "value" }
  }
}
```

**Fixed in v2.1.239**: a bug affecting MCP elicitation forms.

If you're building an MCP server that uses elicitation, see the [MCP elicitation spec](https://modelcontextprotocol.io/docs/learn/client-concepts#elicitation).

## MCP Channels — Push Messages Into a Session (Research Preview, v2.1.80+)

An MCP server can act as a **channel**: instead of only answering tool calls, it pushes messages directly into your session so Claude reacts to external events while you're away — e.g. a Telegram or Discord message, a webhook firing, a CI result, or a monitoring alert.

- The server declares the `claude/channel` capability.
- You opt it in with the `--channels` flag at startup/add time.
- `--channels` permission relay forwards tool approvals to the MCP server (v2.1.81+).

```bash
claude mcp add --transport http --channels my-server https://api.example.com/mcp
```

See the Channels reference for building a custom channel server; officially supported channels (Telegram, Discord, webhooks) are documented separately.

**v2 runtime interaction**: if `MCP_PROTOCOL_NEGOTIATION=auto` and a channel server negotiates the newer MCP protocol revision (2026-07-28), it can't deliver channel messages, so Claude Code does **not** register it as a channel on that revision. Leave the variable unset or set it to `legacy` to keep stdio servers on the earlier handshake that supports channels.

## MCP OAuth CIMD (v2.1.81+)

Support for Client ID Metadata Document (CIMD / SEP-991) for OAuth authentication with MCP servers — see [OAuth Discovery Chain](#oauth-discovery-chain) above for how it's used.

## Using MCP Tools in Claude

Once configured, MCP tools appear with prefix `mcp__ServerName__`:

```
mcp__github__search_repositories
mcp__filesystem__read_file
mcp__postgres__query
```

### Permission Patterns for MCP Tools

Use these forms in `permissions.allow`/`deny`, a skill's `allowed-tools`, a subagent's `tools` field, or a hook matcher:

| Pattern | Matches |
|---|---|
| `mcp__github` | The whole `github` server (all its tools) |
| `mcp__github__search_repositories` | One specific tool |
| `mcp__github__*` | All tools on the `github` server (wildcard) |
| `mcp__*` | All MCP tools, from every server |

**Plugin-bundled servers** use a longer form: `mcp__plugin_<plugin-name>_<server-name>__<tool-name>` (any character outside `A-Z a-z 0-9 _ -` is replaced with `_`). E.g. a `query` tool on a `database-tools` server bundled in plugin `my-plugin` is `mcp__plugin_my-plugin_database-tools__query`. A hook matcher written against the bare server key (`mcp__database-tools__.*`) never matches a plugin-bundled server — you must use the full plugin-prefixed name. The server itself registers under `plugin:<plugin-name>:<server-name>` for fields that expect a server name (e.g. an `mcp_tool` hook's `server` field).

### MCP Resources via @ Mentions
```
@resource_name
```
Use `@server:protocol://resource/path` to reference a specific resource, e.g. `@github:issue://123` or `@docs:file://api/authentication`. Type `@` alone to browse all available resources from connected servers (fuzzy-searchable, alongside files). Claude Code auto-provides list/read tools for resources when a server supports them.

### MCP Prompts as Commands
```
/mcp__servername__promptname
```
Discover them by typing `/`. Pass arguments space-separated: `/mcp__jira__create_issue "Bug in login flow" high`. Server and prompt names are normalized (spaces → underscores); results are injected directly into the conversation.

## Subagent-Scoped MCP Servers

A subagent (`.claude/agents/*.md` or `~/.claude/agents/*.md`) can declare its own `mcpServers` in frontmatter, scoping a server to just that subagent instead of the whole session:

```yaml
---
name: db-agent
description: Runs read-only database queries
mcpServers:
  postgres:
    command: npx
    args: ["-y", "@modelcontextprotocol/server-postgres"]
    env:
      DATABASE_URL: "${DATABASE_URL}"
---
```

Same trust rule as project/local-scope servers applies: Claude Code won't load an agent-file-declared server (or run its `headersHelper`) until you've trusted the project (for a file in the project's `.claude/agents/`) or the `--add-dir` directory it came from. An agent file from `~/.claude/agents/`, from managed settings, or passed via `--agents` isn't subject to that trust gate. Reference the resulting tools the normal way (`mcp__<server>__<tool>`) in that subagent's `tools` field.

## MCP Tool Search

Dynamic tool loading when many MCP servers configured. Requires Sonnet 4+ or Opus 4+ (not available with Haiku).

```bash
ENABLE_TOOL_SEARCH=auto        # Default (10% context threshold)
ENABLE_TOOL_SEARCH=auto:5      # Custom threshold (5%)
ENABLE_TOOL_SEARCH=true        # Always enabled
ENABLE_TOOL_SEARCH=false       # Disabled
```

Disable via `disallowedTools` setting:
```json
{"permissions": {"deny": ["MCPSearch"]}}
```

### Dynamic Tool Updates

MCP servers can send `list_changed` notifications to dynamically update their available tools without reconnecting.

### Reserved Server Names (v2.1.128+)

`workspace` is a reserved MCP server name. Do not use it for custom server configurations.

### `streamable-http` Transport Alias

When configuring servers via JSON (`.mcp.json`, `~/.claude.json`, or `claude mcp add-json`), `"type": "streamable-http"` is accepted as an alias for `"type": "http"`. The MCP spec uses `streamable-http`; Claude Code accepts both so configs copied from server docs work without modification.

### `headersHelper` — Dynamic Authentication Headers

For auth schemes other than OAuth (Kerberos, short-lived tokens, internal SSO), use `headersHelper` to generate headers at connection time:

```json
{
  "mcpServers": {
    "internal-api": {
      "type": "http",
      "url": "https://mcp.internal.example.com",
      "headersHelper": "/opt/bin/get-mcp-auth-headers.sh"
    }
  }
}
```

The helper runs in a shell with a 10-second timeout. It must write a JSON object of string key-value pairs to stdout. Dynamic headers override static `headers` with the same name. Claude Code sets `CLAUDE_CODE_MCP_SERVER_NAME` and `CLAUDE_CODE_MCP_SERVER_URL` env vars so a single helper script can serve multiple servers.

**Fixed in v2.1.248**: a server whose `headersHelper` supplies the `Authorization` header used to fall into OAuth discovery on a 401 response instead of re-running the helper and retrying the call. It now re-runs the helper and retries as documented.

### `oauth.scopes` — Restrict OAuth Scope

Pin the OAuth scopes Claude Code requests, overriding what the server advertises:

```json
{
  "mcpServers": {
    "slack": {
      "type": "http",
      "url": "https://mcp.slack.com/mcp",
      "oauth": {
        "scopes": "channels:read chat:write search:read"
      }
    }
  }
}
```

Space-separated string (RFC 6749 §3.3 format). Takes precedence over `authServerMetadataUrl` and server-advertised scopes.

### `CLAUDE_PROJECT_DIR` in Stdio Server Environment

Claude Code sets `CLAUDE_PROJECT_DIR` in the spawned stdio server's environment to the project root. Servers can read `process.env.CLAUDE_PROJECT_DIR` (Node) or `os.environ["CLAUDE_PROJECT_DIR"]` (Python) to resolve project-relative paths without depending on the working directory. In `.mcp.json` `command`/`args`, reference it as `${CLAUDE_PROJECT_DIR:-.}` (with fallback) since it's set in the server's environment, not Claude Code's own env.

### Automatic Reconnection for HTTP/SSE Servers

If an HTTP or SSE server disconnects mid-session, Claude Code automatically reconnects with exponential backoff: up to five attempts, starting at 1 second and doubling each time. Server appears as pending in `/mcp` during reconnection; marked failed after five attempts. The same backoff applies at initial startup for transient errors (5xx, connection refused, timeout). Authentication and 404 errors are not retried.

### `allowAllClaudeAiMcps` Managed Setting (v2.1.149)

Enterprise managed setting that allows all claude.ai MCP connectors to be available in Claude Code for org users.

### `alwaysLoad` Server Option (v2.1.121+)

Set `alwaysLoad: true` on an MCP server config to skip ToolSearch deferral. Tools from that server are loaded directly into the toolset rather than fetched on-demand by `ToolSearch`. Use for small servers where the latency of search-then-load isn't worth the context savings, or for servers whose tools you want callable without the model first having to search for them.

```json
{
  "mcpServers": {
    "fast-server": {
      "command": "node",
      "args": ["server.js"],
      "alwaysLoad": true
    }
  }
}
```

### Transient Error Auto-Retry (v2.1.121+)

MCP servers that fail with transient errors (network blips, brief service outages) auto-retry up to 3 times before reporting failure. No configuration required — automatic. Reduces flake from servers that briefly drop connections.

### Concurrent Server Startup (v2.1.117+)

MCP servers now start concurrently by default rather than sequentially. Reduces session startup time, especially with many servers configured. `resources/templates/list` is deferred to further accelerate startup (v2.1.116+).

### `${ENV_VAR}` Substitution in Headers (v2.1.119+)

`${ENV_VAR}` placeholders in MCP server headers and config are substituted before server startup. Useful for dynamic credentials and proxy headers:

```json
{
  "mcpServers": {
    "api": {
      "transport": "http",
      "url": "https://api.example.com/mcp",
      "headers": { "Authorization": "Bearer ${API_TOKEN}" }
    }
  }
}
```

## MCP Client Runtimes (v1 vs v2)

Claude Code connects to MCP servers through one of two client runtimes: **v1** (MCP TypeScript SDK 1.x) or **v2** (SDK 2.0, adding MCP protocol revision 2026-07-28). It picks a runtime at startup and keeps it for the session.

- **On v2.1.232+, v2 is the default**, except: on Bedrock/Claude Platform on AWS/Google Cloud Agent Platform/Microsoft Foundry (unless the host sets `CLAUDE_CODE_PROVIDER_MANAGED_BY_HOST`), when signed in through a Claude apps gateway, or with feature-flag fetching off.
- On v2, Claude Code asks HTTP and claude.ai connector servers whether they support the newer revision and uses it if so (stdio servers only if `MCP_PROTOCOL_NEGOTIATION=auto`); receives `list_changed` notifications over a held-open stream; won't register a channel server that negotiates the newer revision (can't carry channel messages); and fails an MCP OAuth sign-in whose response names an unexpected issuer.
- Pick the runtime explicitly with `MCP_SDK_GENERATION=v1|v2`; control whether Claude Code asks with `MCP_PROTOCOL_NEGOTIATION=auto|legacy`.

**Notification streams (v2 runtime)**: when the held-open stream for `list_changed` closes, Claude Code reopens it — up to 3 times if it re-closes within 10s, then stops for that connection; if it stays open >10s before closing (common with serverless hosts), Claude Code waits ~6 hours after 5 reopens in an hour. Until it reopens, you keep the server's last-fetched tools/prompts/resources — reconnect from `/mcp` to refresh sooner.

**Fixed in v2.1.232–v2.1.233**: MCP v2 runtime subscription loops and connection hangs.

## MCP Tool Descriptions (v2.1.84+)

Tool descriptions and instructions are capped at 2KB. Longer descriptions are truncated to prevent context bloat. Ensure descriptions are concise and informative within this limit.

## MCP Server Deduplication (v2.1.84+)

When multiple MCP server configurations define the same server, local config takes precedence (stops further deduplication). This applies to:
- Local configuration (~/.claude.json under project path)
- Project configuration (.mcp.json in project root)
- User configuration (~/.claude.json)
- Managed configuration (managed-mcp.json)

First match wins — no merging of configurations occurs.

## Output Limits

MCP tool output warning at 10,000 tokens. Default max: 25,000 tokens. Increase for large outputs:
```bash
MAX_MCP_OUTPUT_TOKENS=50000 claude
```

### MCP Tool Result Persistence Override (v2.1.91+)

To override default result size limits per tool, MCP servers can annotate their result metadata:
```json
{
  "_meta": {
    "anthropic/maxResultSizeChars": 500000
  }
}
```

This allows individual tools to persist results up to 500KB characters. The MCP server controls this annotation.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MAX_MCP_OUTPUT_TOKENS` | Max tokens in output (default: 25,000) |
| `MCP_TIMEOUT` | Server startup timeout in ms |
| `MCP_CLIENT_SECRET` | OAuth client secret for CI/automation |
| `MCP_CONNECTION_NONBLOCKING` | Set to `true` to skip MCP wait in `-p` mode (v2.1.89+). Uses 5s timeout for MCP connections. |
| `ENABLE_TOOL_SEARCH` | Dynamic tool loading: `auto` (default), `auto:N`, `true`, `false`. Disabled by default when `ANTHROPIC_BASE_URL` is non-first-party |
| `ENABLE_CLAUDEAI_MCP_SERVERS` | Set to `false` to disable claude.ai MCP servers in Claude Code |
| `CLAUDE_CODE_MCP_SERVER_NAME` | Multi-server OAuth header helper: server name for auth discovery (v2.1.85+) |
| `CLAUDE_CODE_MCP_SERVER_URL` | Multi-server OAuth header helper: server URL for auth discovery (v2.1.85+) |
| `ANTHROPIC_CUSTOM_MODEL_OPTION` | Custom model entry in `/model` picker (v2.1.78+) |
| `MCP_SDK_GENERATION` | Force `v1` or `v2` client runtime |
| `MCP_PROTOCOL_NEGOTIATION` | `auto` (ask stdio/channel servers for the newer protocol revision) or `legacy` |
| `CLAUDE_CODE_MCP_TOOL_IDLE_TIMEOUT` | Idle window (ms) before an unresponsive tool call aborts; `0` disables the check. Default: 5 min (HTTP/SSE/WS/connector), 30 min (stdio) |
| `CLAUDE_CODE_MCP_AUTO_BACKGROUND_MS` | Threshold (ms) before a long-running MCP tool call in the main conversation moves to a background task. Default 2 min; `0` disables |
| `MCP_DISCOVERY_CACHE` | `1` to cache remote server tool lists across sessions (shows `cached` status in `/mcp`); `0` to disable. Default varies by rollout (was on-by-default before v2.1.238) |

## CLI Commands

Full `claude mcp` surface:

```bash
# Add servers
claude mcp add --transport http my-server https://example.com/mcp
claude mcp add --transport sse my-server https://example.com/sse      # deprecated transport
claude mcp add --transport stdio my-server -- npx server-package
claude mcp add [options] <name> -- <command> [args...]                # -- separates Claude's flags from the server's

# Import from JSON (supports stdio/http/sse/ws entries, oauth object, etc.)
claude mcp add-json my-server '{"command": "node", "args": ["server.js"]}'

# Import from Claude Desktop (macOS + WSL only)
claude mcp add-from-claude-desktop

# List / inspect / remove
claude mcp list                 # health status per server: Connected / Needs authentication / Failed / Pending approval
claude mcp get <name>           # full detail incl. Issue: line on failure
claude mcp remove <name>

# Authentication
/mcp                       # in-session: OAuth setup, reconnect, clear auth, view cached/tool-count status
claude mcp login <name>    # run OAuth flow from the shell (v2.1.186+)
claude mcp logout <name>   # clear stored credentials
claude mcp login <name> --no-browser   # force the paste-URL flow (v2.1.191+)

# Use Claude Code as an MCP server
claude mcp serve

# Reset project (.mcp.json) approval choices
claude mcp reset-project-choices
```

**Scope flags** (accepted by `add`/`add-json`): `-s`/`--scope local|project|user` (default `local`). Other flags: `-t`/`--transport`, `-H`/`--header`, `-e`/`--env KEY=value` (repeatable; needs another flag between `--env` and the server name), `--client-id`, `--client-secret` (masked prompt; or set `MCP_CLIENT_SECRET` for CI), `--callback-port`.

**Server names** may contain only letters, numbers, hyphens, and underscores. Reserved and rejected by `claude mcp add`: `workspace`, `claude-in-chrome`, `computer-use`, `Claude Preview`, `Claude Browser`.

## Managed MCP (Enterprise)

### Option 1: Exclusive control via `managed-mcp.json`
Deploy fixed servers that users cannot modify (macOS: `/Library/Application Support/ClaudeCode/managed-mcp.json`):
```json
{
  "mcpServers": {
    "company-tools": {
      "type": "http",
      "url": "https://internal.company.com/mcp"
    }
  }
}
```

### Option 2: Policy-based control via managed settings
Allow users to add servers within restrictions. Each entry uses one of: `serverName`, `serverCommand`, or `serverUrl`:

```json
{
  "allowedMcpServers": [
    {"serverName": "github"},
    {"serverCommand": ["npx", "-y", "@approved/package"]},
    {"serverUrl": "https://mcp.company.com/*"}
  ],
  "deniedMcpServers": [
    {"serverUrl": "https://*.untrusted.com/*"}
  ]
}
```

Denylist takes absolute precedence over allowlist.

## Plugin MCP Servers

In plugin's `.mcp.json` or `plugin.json`:
```json
{
  "mcpServers": {
    "plugin-server": {
      "command": "${CLAUDE_PLUGIN_ROOT}/server.js"
    }
  }
}
```

Claude can use them like built-in tools, e.g. calling `mcp__github__search_repositories` with a `query` parameter.

**Path placeholders** (substituted in `command`/`args`/`env` for stdio, `url`/`headers`/`headersHelper` for http/sse/ws): `${CLAUDE_PLUGIN_ROOT}` — the plugin's install dir; `${CLAUDE_PLUGIN_DATA}` — its persistent state dir; `${CLAUDE_PROJECT_DIR}` — the stable project root (substituted directly for plugins, no `:-default` needed).

**Lifecycle**: servers for enabled plugins connect automatically at session startup (a remote plugin server you've used before may show cached status and connect lazily, on first tool call). Run `/reload-plugins` after enabling/disabling a plugin mid-session to connect/disconnect its servers — live connections of unchanged servers are kept across a reload.

**Tool naming**: full form is `mcp__plugin_<plugin-name>_<server-name>__<tool-name>` — see [Permission Patterns for MCP Tools](#permission-patterns-for-mcp-tools) above.

## Troubleshooting

| Symptom | Cause / Fix |
|---|---|
| `MCP server "<name>" has a "url" but no "type"...` | JSON entry with `url` but no `type` is read as stdio and skipped. Add `"type": "http"` / `"sse"` / `"ws"`. (Before v2.1.202 this showed as `command: expected string, received undefined`.) |
| Server stuck at `⏸ Pending approval` in a freshly cloned repo | Project (`.mcp.json`) approvals committed to `.claude/settings.json` don't apply until you trust the workspace. Run `claude` interactively and accept the trust dialog, or approve from `~/.claude/settings.json` / managed settings instead. |
| `claude mcp add` rejects the server name | Reserved names (`workspace`, `claude-in-chrome`, `computer-use`, `Claude Preview`, `Claude Browser`) or characters outside letters/numbers/hyphens/underscores. |
| `✘ Failed to connect` with no detail | Run `claude mcp get <name>` for the `Issue:` line (HTTP status / error text; credential-like text is redacted, expanded URLs are never shown). `✘ Connection error` shows no detail at all, since the exception text could embed a secret-bearing URL. |
| Server flagged as `not configured` | Empty `url` in its config (common for a plugin placeholder you haven't filled in yet) — Claude Code won't attempt to connect. |
| `Leading or trailing whitespace in: headers.Authorization` (or similar) | Config field (`command`, `url`, `args`, `env`/`headers` keys or values) has hidden whitespace, usually from pasting a token with a trailing newline. Claude Code does **not** trim it — edit the value yourself. |
| OAuth sign-in fails with a redirect URI mismatch | Registered redirect URI must match exactly. On v2.1.229 Claude Code sent `http://127.0.0.1:PORT/callback` instead of `http://localhost:PORT/callback`, breaking exact-match servers — fixed in v2.1.231. Use `--callback-port` to pin a port matching your registered URI. |
| "Incompatible auth server: does not support dynamic client registration" | Server needs pre-configured OAuth credentials (`--client-id`/`--client-secret`) or uses CIMD (usually auto-discovered). |
| Server needs auth but you're in `claude -p`/headless mode | No `/mcp` panel is available. As of v2.1.196, with tool search on (default), Claude is told the server needs sign-in and can say so. Complete sign-in from an interactive session with `/mcp` or `claude mcp login <name>`. |
| `claude.ai` connector missing from `/mcp` | Connectors load only when your active auth is a claude.ai subscription login — check with `/status`. An `ANTHROPIC_API_KEY`, `apiKeyHelper`, third-party provider (Bedrock/Vertex), or `CLAUDE_CODE_OAUTH_TOKEN` from `claude setup-token` all suppress connector loading. |
| Connector shows `connected · session token rejected` | Your Claude Code login expired/couldn't refresh; re-authorizing the connector won't fix it. Run `/login` again, then reconnect the connector from `/mcp`. (Before v2.1.222 this showed as "needs authentication" instead, and re-auth didn't resolve it.) |
| `headersHelper` never runs (`headersHelper not run` on stderr) | Project/local-scope server or agent-file-declared server whose folder you haven't trusted yet. A parent folder's trust doesn't count; grant `hasTrustDialogAccepted: true` for the exact path in `~/.claude.json`, or trust interactively. |
| `spawn claude ENOENT` when using `claude mcp serve` from Claude Desktop | `claude` isn't on the configured client's PATH — use the full path from `which claude` in the `command` field. |
| MCP tool output truncated / warning shown | Output warning fires at 10K tokens, hard cap defaults to 25K (`MAX_MCP_OUTPUT_TOKENS`). A tool can raise its own cap via `_meta["anthropic/maxResultSizeChars"]` (up to 500K chars) — doesn't help image output, only text. |
| Tool call silently hangs then errors after several minutes | Idle timeout (`CLAUDE_CODE_MCP_TOOL_IDLE_TIMEOUT`, default 5 min HTTP/SSE/WS/connector or 30 min stdio) or the per-server/`MCP_TOOL_TIMEOUT` wall-clock limit was hit with no response/progress notification from the server. |