# MCP (Model Context Protocol) Reference

## What Is MCP?

MCP (Model Context Protocol) is a standard for connecting AI assistants to external tools and data sources. MCP servers provide:
- **Tools**: Functions Claude can call (e.g., search, API calls)
- **Resources**: Data Claude can access (e.g., files, databases)
- **Prompts**: Pre-defined prompt templates

## Configuration Location

MCP servers are configured in `~/.claude/.mcp.json`:

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

Alternative locations:
- Project level: `.claude/.mcp.json`
- Global: `~/.claude/.mcp.json`

## Transport Types

### stdio (Most Common)
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

### SSE (Server-Sent Events)
For HTTP-based servers:

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

Claude can use them like built-in tools:
```
<function_calls>
<invoke name="mcp__github__search_repositories">
<parameter name="query">claude code