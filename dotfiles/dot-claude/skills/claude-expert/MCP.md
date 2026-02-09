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

For servers requiring OAuth 2.0, use `/mcp` inside Claude Code to authenticate via browser. Tokens are stored securely and refreshed automatically.

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

## Using MCP Tools in Claude

Once configured, MCP tools appear with prefix `mcp__ServerName__`:

```
mcp__github__search_repositories
mcp__filesystem__read_file
mcp__postgres__query
```

### MCP Resources via @ Mentions
```
@resource_name
```

### MCP Prompts as Commands
```
/mcp__servername__promptname
```

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

## Output Limits

MCP tool output warning at 10,000 tokens. Default max: 25,000 tokens. Increase for large outputs:
```bash
MAX_MCP_OUTPUT_TOKENS=50000 claude
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MAX_MCP_OUTPUT_TOKENS` | Max tokens in output (default: 25,000) |
| `MCP_TIMEOUT` | Server startup timeout in ms |
| `MCP_CLIENT_SECRET` | OAuth client secret for CI/automation |
| `ENABLE_TOOL_SEARCH` | Dynamic tool loading: `auto` (default), `auto:N`, `true`, `false` |

## CLI Commands

```bash
# Add servers
claude mcp add --transport http my-server https://example.com/mcp
claude mcp add --transport stdio my-server -- npx server-package

# Import from JSON
claude mcp add-json my-server '{"command": "node", "args": ["server.js"]}'

# Import from Claude Desktop
claude mcp add-from-claude-desktop

# Use Claude Code as MCP server
claude mcp serve

# Authentication
/mcp  # In Claude Code for OAuth setup

# Reset project choices
claude mcp reset-project-choices
```

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

Claude can use them like built-in tools:
```
<function_calls>
<invoke name="mcp__github__search_repositories">
<parameter name="query">claude code