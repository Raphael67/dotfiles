# OpenRouter Reference

OpenRouter is a unified API gateway providing access to hundreds of AI models through a single endpoint, with automatic fallback handling, cost-effective routing, and extensive optimization features.

## API Basics

**Endpoint**: `https://openrouter.ai/api/v1/chat/completions`

**Authentication**:
```bash
curl https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "HTTP-Referer: https://your-site.com" \
  -H "X-OpenRouter-Title: Your App Name" \
  -d '{"model": "anthropic/claude-sonnet-4", "messages": [...]}'
```

**SDK Options**:

| SDK | Setup |
|-----|-------|
| OpenRouter SDK (TS) | `npm install @openrouter/sdk` |
| OpenAI SDK (compatible) | Set `baseURL: 'https://openrouter.ai/api/v1'` |
| Go SDK | `go get github.com/openrouter/openrouter-go` |
| Python (OpenAI) | Set `base_url="https://openrouter.ai/api/v1"` |

OpenAPI spec: `openrouter.ai/openapi.json` / `openrouter.ai/openapi.yaml`

## Routing & Optimization

### Model Fallbacks
Automatic failover between providers when primary is unavailable or rate-limited.

### Provider Routing
Intelligent request distribution across vendors for optimal latency and availability.

### Auto Exacto
Optimizes provider ordering for tool-calling using throughput and success metrics. Automatically enabled for tool-use requests.

### Model Variants

| Variant | Suffix | Description |
|---------|--------|-------------|
| Free | `:free` | Free tier with rate limits |
| Extended | `:extended` | Extended context window |
| Exacto | `:exacto` | Optimized for tool calling |
| Thinking | `:thinking` | Chain-of-thought reasoning |
| Online | `:online` | Web search integrated |
| Nitro | `:nitro` | Optimized for speed |

### Other Routing Features
- **Auto Router** (powered by NotDiamond) — intelligent model selection
- **Body Builder** — parallel execution across providers
- **Free Models Router** — route to best free model
- **Service Tiers** — cost/latency tradeoffs
- **Zero Completion Insurance** — protection against failed responses

## Capabilities

### Multimodal
- **Input**: images, PDFs, audio, video
- **Output**: image generation, video generation

### Tool & Function Calling
Supports OpenAI, Anthropic, and other tool-calling formats natively.

### Server Tools
Built-in server-side tools:
- Web search
- Datetime
- Image generation

### Plugins
- Web search plugin
- PDF processing
- Response healing (auto-fix malformed outputs)

### Structured Outputs
JSON Schema validation for guaranteed output format.

### Streaming
Server-Sent Events (SSE) for real-time token streaming.

## Cost Optimization

### Prompt Caching
Reduces cost by caching repeated prompt prefixes. Works with providers that support it (Anthropic, OpenAI).

### Message Transforms
Automatic context window optimization — truncates messages to fit model limits.

### BYOK (Bring Your Own Keys)
Use existing provider API keys through OpenRouter for routing benefits without markup.

### Guardrails
Spending limits and access restrictions per API key.

### Zero Data Retention
Option to prevent data storage at the provider level.

## Observability (Broadcast)

Connect to monitoring platforms:

| Category | Services |
|----------|----------|
| AI/ML Ops | Arize AI, Braintrust, Langfuse, LangSmith, W&B Weave |
| General Ops | Datadog, Grafana Cloud, New Relic, Sentry |
| Data | ClickHouse, S3, Snowflake, PostHog |
| Other | Comet Opik, OpenTelemetry Collector, Ramp, Webhook |

## Coding Agent Integrations

Dedicated documentation and configuration guides for:

| Agent | Integration |
|-------|-------------|
| Claude Code | `ANTHROPIC_BASE_URL=https://openrouter.ai/api/v1` |
| Codex CLI | OpenAI-compatible endpoint |
| OpenCode | Provider config in opencode.jsonc |
| Pi | Provider config or `pi.registerProvider()` |
| MCP Servers | Standard MCP tool interface |

### Claude Code Configuration
```bash
export ANTHROPIC_BASE_URL="https://openrouter.ai/api/v1"
export ANTHROPIC_API_KEY="sk-or-..."
# Model selection via claude --model
```

### Pi Configuration
```json
// ~/.pi/agent/settings.json
{
  "defaultProvider": "openrouter",
  "providers": {
    "openrouter": {
      "apiKey": "sk-or-...",
      "defaultModel": "anthropic/claude-opus-4-6"
    }
  }
}
```

### OpenCode Configuration
```jsonc
// .opencode/opencode.jsonc
{
  "provider": {
    "openrouter": {
      "options": {
        "apiKey": "${env:OPENROUTER_API_KEY}"
      }
    }
  }
}
```

## Framework Support

Compatible with major AI frameworks:

| Framework | Language | Notes |
|-----------|----------|-------|
| Vercel AI SDK | TypeScript | Native provider |
| LangChain | Python/JS | OpenAI-compatible |
| Anthropic Agent SDK | Python | Via base_url override |
| PydanticAI | Python | OpenAI-compatible |
| TanStack AI | TypeScript | Via provider config |
| Mastra | TypeScript | Native integration |
| LiveKit Agents | Python | Real-time voice/video |

## Agent SDK

OpenRouter provides its own agent SDK for multi-turn workflows:

```typescript
import { OpenRouter } from "@openrouter/sdk";

const client = new OpenRouter({ apiKey: "sk-or-..." });

// Single call with tool execution
const result = await client.chat.completions.create({
  model: "anthropic/claude-sonnet-4",
  messages: [...],
  tools: [...],
});
```

Key agent SDK features:
- `callModel` for text generation, streaming, and tool calling with automatic execution
- Dynamic parameters for async computation
- Stop conditions controlling multi-turn execution
- Tool approval and state persistence for human-in-the-loop
- Migration path from `@openrouter/sdk` to `@openrouter/agent`

## Administration

| Feature | Description |
|---------|-------------|
| OAuth PKCE | Secure authentication flow |
| Management API Keys | Programmatic key creation and rotation |
| Organization Management | Team-level access control |
| Usage Accounting | Per-key and per-user tracking |
| Activity Export | CSV/PDF export of usage data |
| Rate Limiting | Per-key and per-model limits |

## Model Selection Strategy

### By Task Type
| Task | Recommended Approach |
|------|---------------------|
| Complex reasoning | `:thinking` variant or Opus-class model |
| Tool-heavy workflows | `:exacto` variant for reliable tool calling |
| Fast iteration | `:nitro` variant or Haiku-class model |
| Cost-sensitive | `:free` variant or economy models |
| Web-grounded | `:online` variant for search integration |

### By Cost Tier
| Tier | Models | Cost Range |
|------|--------|------------|
| Premium | claude-opus-4-6, gpt-5.1, gemini-2.5-pro | $10-30/M tokens |
| Balanced | claude-sonnet-4, gpt-4o, gemini-2.0-flash | $1-5/M tokens |
| Economy | claude-haiku-4-5, gpt-4o-mini, gemini-flash | $0.1-1/M tokens |
| Free | Various `:free` variants | $0 (rate limited) |
