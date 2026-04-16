# Models & Cost Reference

Cross-harness guide for model selection, cost optimization, thinking levels, and context management.

## Model Families

### Claude (Anthropic)

| Model | Context | Max Output | Strengths |
|-------|---------|------------|-----------|
| claude-opus-4-6 | 200K (1M beta) | 32K | Best reasoning, complex tasks, agent orchestration |
| claude-sonnet-4-6 | 200K | 16K | Balanced performance/cost, coding, tool use |
| claude-haiku-4-5 | 200K | 8K | Fast, cheap, simple tasks, exploration |

### GPT (OpenAI)

| Model | Context | Strengths |
|-------|---------|-----------|
| gpt-5.1 / gpt-5.1-codex | 256K | Complex reasoning, coding, long context |
| gpt-4.5 | 128K | Creative writing, nuanced understanding |
| gpt-4o | 128K | Balanced, multimodal, fast |
| gpt-4o-mini | 128K | Economy, simple tasks |

### Gemini (Google)

| Model | Context | Strengths |
|-------|---------|-----------|
| gemini-2.5-pro | 1M | Longest context, complex reasoning |
| gemini-2.5-flash | 1M | Fast, long context, cost-effective |
| gemini-2.0-flash | 1M | Balanced speed/quality |

### Open Models

| Model | Context | Provider | Strengths |
|-------|---------|----------|-----------|
| DeepSeek V3/R1 | 128K | DeepSeek, OpenRouter | Coding, reasoning, cost-effective |
| Llama 4 | 128K | Meta, Groq, Together | Open weights, fast inference |
| Mistral Large | 128K | Mistral | European, multilingual |
| Qwen 3 | 128K | Alibaba | Coding, multilingual |

## Cost Tiers

### Per Million Tokens (Approximate)

| Tier | Input | Output | Models |
|------|-------|--------|--------|
| **Premium** | $10-15 | $30-75 | Opus 4.6, GPT-5.1 |
| **Balanced** | $1-3 | $5-15 | Sonnet 4.6, GPT-4o, Gemini 2.5 Pro |
| **Economy** | $0.10-1 | $0.50-5 | Haiku 4.5, GPT-4o-mini, Gemini Flash |
| **Free/Open** | $0-0.10 | $0-0.50 | DeepSeek, Llama, free variants |

### Cost Reduction Strategies

| Strategy | Savings | How |
|----------|---------|-----|
| Prompt caching | 50-90% on input | Anthropic/OpenAI native caching |
| Model tiering | 80-95% | Use Haiku for exploration, Opus for complex tasks |
| OpenRouter free | 100% | `:free` variants (rate limited) |
| Compaction | Variable | Summarize old context instead of full replay |
| Context pruning | Variable | Pi `context` event to filter before submission |

## Thinking / Reasoning Levels

### Claude Code
| Level | Budget | Use Case |
|-------|--------|----------|
| low | Default | Standard tasks |
| medium | Extended | Complex reasoning |
| high | Large | Deep analysis, planning |

Configure: `/effort`, `--effort`, agent frontmatter `effort: high`

### Pi
| Level | Budget (tokens) | Use Case |
|-------|----------------|----------|
| off | 0 | Simple responses |
| minimal | 128 | Quick thinking |
| low | 512 | Standard tasks |
| medium | 1024 | Complex reasoning |
| high | 2048 | Deep analysis |
| xhigh | 4096+ | Maximum reasoning |

Configure: `Shift+Tab` to cycle, settings `defaultThinkingLevel`, per-model scope `model:high`

### OpenCode
Thinking levels depend on provider support. Anthropic provider includes `interleaved-thinking` beta header.

### OpenRouter
Use `:thinking` model variant for chain-of-thought reasoning across any supported provider.

## Model Selection Strategy

### By Task Complexity

| Task Type | Recommended Tier | Examples |
|-----------|-----------------|----------|
| Exploration / search | Economy | File search, grep, quick reads |
| Simple edits | Economy-Balanced | Typo fixes, renames, simple refactors |
| Feature implementation | Balanced | New features, bug fixes, moderate complexity |
| Architecture / planning | Premium | System design, complex refactors, agent orchestration |
| Code review / security | Balanced-Premium | Security audit, performance review |
| Documentation | Economy-Balanced | READMEs, comments, specs |

### By Agent Role

| Agent Role | Model Tier | Reasoning |
|------------|-----------|-----------|
| Lead / orchestrator | Premium (Opus) | Needs best judgment for coordination |
| Builder / implementer | Balanced (Sonnet) | Good coding, reasonable cost |
| Explorer / researcher | Economy (Haiku) | Fast, read-only, high volume |
| Validator / reviewer | Balanced (Sonnet) | Needs good judgment, read-heavy |
| Meta-agent | Premium (Opus) | Generates other agents, needs deep understanding |

### By Harness

| Harness | Default Model | Override Method |
|---------|--------------|-----------------|
| Claude Code | claude-sonnet-4-6 | `--model`, `/model`, agent frontmatter, env var |
| Pi | claude-opus-4-6 (Anthropic) | `Ctrl+L` selector, `Ctrl+P` cycle, `/model`, settings |
| OpenCode | Depends on provider | Tab to switch agents, agent config, `/connect` |
| OpenRouter | Specified per request | `model` field in API call |

## Context Windows

### Sizes

| Model | Context | Effective (after system prompt) |
|-------|---------|-------------------------------|
| Claude Opus/Sonnet | 200K (1M beta) | ~190K (CC ~10K system) |
| Claude via Pi | 200K | ~199.8K (Pi ~200 token system) |
| GPT-5.1 | 256K | ~250K |
| Gemini 2.5 | 1M | ~990K |
| Most open models | 128K | ~120K |

### Compaction Strategies

| Harness | Method | Trigger |
|---------|--------|---------|
| Claude Code | Auto-compaction at 95% | Automatic, override with `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` |
| Pi | Manual `/compact` or auto on overflow | Customizable via extension hooks |
| OpenCode | Compaction agent | Automatic with customization |

### Prompt Cache Optimization

| Provider | Cache Type | Duration | Savings |
|----------|-----------|----------|---------|
| Anthropic | Automatic | 5 min | 90% on cached input |
| OpenAI | Automatic | ~1 hour | 50% on cached input |
| Google | Context caching | Configurable | Variable |

**CC-specific**: Tool ordering is sorted alphabetically for prompt-cache stability. Built-in tools form contiguous prefix; MCP tools appended after.

**Pi-specific**: Minimal system prompt (~200 tokens) means less to cache but also less overhead. Extensions can inject dynamic content that busts cache.

## Provider Routing Decision Tree

```
Need specific model? ─── Yes ──→ Direct API to provider
       │
       No
       │
Need fallbacks/routing? ─── Yes ──→ OpenRouter
       │
       No
       │
Single provider? ─── Yes ──→ Direct API (cheapest)
       │
       No
       │
Multi-provider switching? ──→ Pi (native) or OpenCode (AI SDK) or OpenRouter (gateway)
```

## Cross-Provider Considerations

| Factor | Direct API | OpenRouter | Pi Native | OC AI SDK |
|--------|-----------|------------|-----------|-----------|
| Latency | Lowest | +10-50ms | Same as direct | Same as direct |
| Cost | Base price | +markup | Base price | Base price |
| Fallbacks | Manual | Automatic | Manual | Manual |
| Model switching | Restart | Change model field | Ctrl+L/P | Agent config |
| Observability | DIY | Broadcast built-in | Extension events | Limited |
| Auth | Per-provider | Single key | Per-provider | Per-provider |
