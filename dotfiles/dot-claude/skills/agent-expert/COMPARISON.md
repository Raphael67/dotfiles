# Agent Harness Comparison Matrix

Cross-harness reference for Claude Code, Pi, OpenCode, and OpenRouter.

---

## Design Philosophy

| Dimension | Claude Code | Pi | OpenCode |
|-----------|-------------|-----|----------|
| Mantra | "Tool for every engineer" — batteries-included | "If I don't need it, won't build it" — minimal, extensible | "Claude Code replacement" — open, feature-parity |
| Source | Proprietary | MIT open source | MIT open source |
| System prompt | ~10,000+ tokens | ~200 tokens | ~5,000 tokens |
| Observability | Abstracted (sub-agents are black boxes) | Full transparency (every token visible) | Moderate (logs, session export) |
| Context control | Managed (auto-compaction, sub-agents) | User-controlled (no hidden injections) | Managed with customization hooks |
| Multi-model | Anthropic-first (gateway workaround) | Model-agnostic (20+ providers native) | Model-agnostic (75+ providers via SDK) |

**Key tension**: Claude Code optimizes for out-of-box capability and enterprise trust. Pi optimizes for transparency and extensibility. OpenCode optimizes for open-source parity and portability.

---

## Tool Comparison Table

| Tool Category | Tool | Claude Code | Pi | OpenCode |
|---------------|------|-------------|-----|----------|
| **File ops** | Read file | Yes | Yes | Yes |
| | Write file | Yes | Yes | Yes |
| | Edit file (patch) | Yes | Yes | Yes |
| | Multi-file edit | Yes | Yes | Yes |
| **Search** | Glob (file pattern) | Yes | Yes | Yes |
| | Grep (content search) | Yes | Yes | Yes |
| | Semantic search | No | No | No |
| **Shell** | Bash execution | Yes | Yes | Yes |
| | Bash with timeout | Yes | Yes | Yes |
| | Background tasks | Yes | Yes | Yes |
| **Web** | Fetch URL | Yes | Yes | Yes |
| | Browser automation | No | No | No |
| **Notebooks** | Jupyter read/run | Yes | No | Yes |
| **Agents** | Sub-agents | Yes | Yes | Yes |
| | Agent teams | Yes | Yes | No (custom) |
| | Dispatcher pattern | No | Yes (ext) | No |
| **Integration** | MCP client | Yes | Yes | Yes |
| | MCP server | No | No | No |
| | LSP integration | No | No | Yes |
| **Workflow** | Plan mode | Yes | Yes (ext) | Yes |
| | Todo management | Yes | No | No |
| | Skills / memory | Yes | No | No |
| **Permissions** | Tool allow/deny | Yes | Yes | Yes |
| | Path-based rules | Yes | Yes | Partial |
| | Bash hook intercept | Yes (hook) | Yes (hook) | Partial |

Notes:
- "Yes (ext)" means available via extension, not built-in
- OpenCode LSP integration enables code-aware navigation without a separate tool
- Claude Code's Todo management is native (TodoRead/TodoWrite tools)

---

## Extension and Hook System

### Hook Event Coverage

| Event | Claude Code | Pi | OpenCode |
|-------|-------------|-----|----------|
| Total hook points | ~14 | 25+ | ~20 |
| Pre-tool execution | Yes | Yes | Yes |
| Post-tool execution | Yes | Yes | Yes |
| Pre-bash | Yes | Yes | Yes |
| Post-bash | Yes | Yes | Yes |
| Input interception | No | Yes | No |
| Dynamic system prompt | No | Yes | No |
| Tool result streaming | No | Yes | No |
| Context manipulation | No | Yes | No |
| Before agent start | No | Yes | No |
| Agent stop hook | Yes | Yes | Yes |
| Teammate idle | Yes | No | No |
| Task completed | Yes | No | No |
| Session start/end | Yes | Yes | Yes |
| File write hook | Yes | Yes | Yes |
| Notification hook | Yes | Yes | Partial |
| Branching / snapshot | No | Yes | No |

### Claude Code Hook Events (14)

- `PreToolUse` — intercept any tool call before execution
- `PostToolUse` — react after any tool call completes
- `Notification` — async alerts (token limits, long tasks)
- `Stop` — agent finishes a turn; exit 2 to loop back
- `SubagentStop` — sub-agent finishes; exit 2 to send feedback
- `TeammateIdle` — teammate has no pending tasks; exit 2 to reassign
- `TaskCompleted` — task marked done; exit 2 to prevent completion
- `PreBashExecute`, `PostBashExecute` — shell command lifecycle
- `PreFileWrite`, `PostFileWrite` — file write lifecycle
- `SessionStart`, `SessionEnd` — session boundaries
- `ModelResponse` — raw model output available

### Pi Hook Events (25+ unique capabilities)

All Claude Code events, plus:

- `before_agent_start` — modify agent config before launch
- `on_input` — intercept and transform user input
- `on_tool_stream` — react to tool results as they stream
- `on_context_window` — inspect or modify context before send
- `on_bash_spawn` — intercept shell process creation
- `on_branch` — snapshot context for parallel exploration
- `on_merge` — merge results from branched contexts
- `on_extension_load` — react when an extension activates
- `pi.events` — peer-to-peer event bus for inter-extension messaging
- Dynamic system prompt injection at runtime

**Pi's unique power**: hooks can modify inputs, outputs, and context in flight. Claude Code hooks can only observe and signal (exit codes).

### OpenCode Hook Events (~20)

Covers standard tool lifecycle, session events, and file events. Supports custom middleware. Gaps compared to Pi:

- No `on_input` interception
- No `before_agent_start` (agents are configured statically)
- No branching/snapshot
- No tool result streaming hooks

### Claude Code Hook Gaps

- No input interception (can't rewrite user prompt)
- No dynamic system prompt (system prompt is fixed at session start)
- No tool streaming (hooks fire after tool completes, not during)
- No context manipulation (can't remove or inject tokens mid-session)
- No branching (linear context only)

---

## Multi-Agent Capabilities

| Feature | Claude Code | Pi | OpenCode |
|---------|-------------|-----|----------|
| Native sub-agents | Yes | Yes | Yes |
| Agent teams (named teammates) | Yes | Yes (ext) | No |
| Dispatcher pattern | No | Yes (ext) | No |
| Sequential pipeline | Yes (manual) | Yes (ext) | Yes (manual) |
| Multi-model per agent | No | Yes | Yes |
| Meta-agent (agent builder) | Yes (manual) | Yes (ext) | Yes (manual) |
| Parallel fan-out | Yes | Yes | Yes |
| Shared task list | Yes (TodoWrite) | No | No |
| Peer-to-peer messaging | Yes (teams) | Yes (events) | No |
| Agent grid dashboard | No | Yes (ext) | No |

**Claude Code teams**: named agents with defined roles, scoped tools, and task queues. Coordinator can block on TeammateIdle.

**Pi dispatcher**: YAML team roster, central orchestrator assigns tasks dynamically, grid dashboard shows live status.

**OpenCode**: sub-agents via custom subagent definitions. No native team primitives — orchestration is implemented in agent logic.

---

## Session Architecture

| Aspect | Claude Code | Pi | OpenCode |
|--------|-------------|-----|----------|
| Storage format | JSONL (linear) | JSONL tree | SQLite (linear) |
| Branching | No | Yes | No |
| Session export | Yes | Yes | Yes |
| Resume session | Yes | Yes | Yes |
| Context compaction | Automatic | Manual / hook | Automatic |
| Sub-agent isolation | Full (separate process) | Full | Full |
| Token visibility | Partial (usage stats) | Full (every token) | Partial |
| Replay / audit | Partial (transcript) | Full (event log) | Partial |

**Pi branching**: creates a snapshot of the context tree at any point. Allows exploring multiple hypotheses without contaminating the main thread. Branches can be merged back.

**Claude Code compaction**: automatic summarization when context approaches limit. User has no control over what is summarized.

---

## Provider and Model Support

| Aspect | Claude Code | Pi | OpenCode | OpenRouter |
|--------|-------------|-----|----------|------------|
| Official providers | 4 | 20+ | 75+ via SDK | Hundreds |
| Anthropic direct | Yes | Yes | Yes | Yes |
| AWS Bedrock | Yes | Yes | Yes | Via proxy |
| Google Vertex | Yes | Yes | Yes | Via proxy |
| Azure / Foundry | Yes | Yes | Yes | Via proxy |
| OpenAI | Via gateway | Yes | Yes | Yes |
| Google Gemini | Via gateway | Yes | Yes | Yes |
| Groq / Together / Fireworks | No | Yes | Yes | Yes |
| Ollama (local) | No | Yes | Yes | No |
| OpenRouter | Via gateway | Yes | Yes | N/A |
| Per-agent model selection | No | Yes | Yes | N/A |
| Model fallback / retry | No | Yes (hook) | Partial | Yes |

**Claude Code multi-model workaround**: use an MCP server or proxy that routes to another provider. Not native.

**Pi per-agent model**: each teammate or sub-agent can use a different provider and model. The orchestrator can use Claude for planning and GPT-4 for code generation.

---

## Cost and Licensing

| Aspect | Claude Code | Pi | OpenCode |
|--------|-------------|-----|----------|
| License | Proprietary | MIT | MIT |
| Primary cost driver | Subscription + API tokens | API tokens only | API tokens only |
| System prompt overhead | ~10,000+ tokens per session | ~200 tokens per session | ~5,000 tokens per session |
| Cost visibility | Partial (session usage) | Full (token-by-token) | Moderate (session total) |
| Self-hostable | No | Yes | Yes |
| Subscription required | Yes (Claude Max or API) | No | No |
| Free tier | No | No (pay per token) | No (pay per token) |

**System prompt cost impact**: At $3/M input tokens (Claude Sonnet), a 10,000-token system prompt costs $0.03 per session start and recurs on every context compaction. At scale (1,000 sessions/day), that is $30/day in system prompt overhead alone. Pi's 200-token system prompt costs $0.0006 per session.

---

## Decision Tree: When to Use Which Harness

```
Start
  |
  +-- Need enterprise SSO, audit logs, team billing?
  |     YES --> Claude Code (enterprise)
  |
  +-- Need IDE integration (Cursor, VS Code)?
  |     YES --> Claude Code (native IDE support)
  |
  +-- Need open-source, self-hostable, community fork?
  |     YES --> OpenCode
  |
  +-- Need LSP-aware code navigation?
  |     YES --> OpenCode
  |
  +-- Need 75+ model providers, multi-model per agent?
  |     YES --> Pi or OpenCode
  |
  +-- Need maximum hook extensibility?
  |   (input interception, dynamic system prompts, branching)
  |     YES --> Pi
  |
  +-- Need minimal token overhead and full transparency?
  |     YES --> Pi
  |
  +-- Need model routing, cost optimization, fallback?
  |     YES --> OpenRouter (as gateway for any harness)
  |
  +-- None of the above?
        --> Claude Code (best defaults, largest ecosystem)
```

### Use Claude Code When

- Working within an Anthropic enterprise agreement
- Team needs shared context, billing, and audit trails
- Deep IDE integration is required (native Cursor/VS Code support)
- Claude models are the only requirement (no multi-provider need)
- Onboarding non-technical users who need guided defaults

### Use Pi When

- Maximum hook extensibility is the priority
- Multi-provider or per-agent model selection is required
- Context transparency and token visibility matter
- System prompt overhead is a cost concern at scale
- Building custom agent UIs or embedding agents in products
- Branching and context snapshot patterns are needed

### Use OpenCode When

- Open-source requirement (MIT, auditable codebase)
- Claude Code feature-parity with provider flexibility
- LSP integration for deep code navigation
- Self-hosting in air-gapped or regulated environments
- Community-supported forks and extensions

### Use OpenRouter When

- Routing requests across 200+ models based on cost or latency
- A/B testing models on the same prompt
- Fallback chains (try Claude, fall back to GPT-4, fall back to Gemini)
- Centralizing API key management across multiple harnesses
- Not a primary harness — use as infrastructure beneath any of the above

---

## The One-Line Thesis

> "Pi is a platform. OpenCode is a product. Claude Code is an enterprise product. OpenRouter is infrastructure."

- **Pi**: extensible runtime for building agent systems; you bring your own UI, tools, and opinions
- **OpenCode**: polished replacement for Claude Code with open-source flexibility
- **Claude Code**: turnkey agent with enterprise-grade defaults, team features, and deep Anthropic integration
- **OpenRouter**: model layer — routes, routes, and routes; not an agent harness but works with all of them
