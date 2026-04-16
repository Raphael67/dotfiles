# Pi Coding Agent — Comprehensive Reference

Pi is a minimal, extensible terminal coding agent by Mario Zechner (Earendil Inc.), MIT licensed.
Website: shittycodingagent.ai. Install: `npm install -g @mariozechner/pi-coding-agent`.
Current version: 0.54.2. Philosophy: "Adapt pi to your workflows, not the other way around."

---

## Architecture

Pi is a 7-package TypeScript monorepo (~92,700 lines) with lockstep versioning.

| Package | Role |
|---------|------|
| `pi-ai` | Unified provider abstraction for 20+ LLM providers |
| `pi-agent-core` | Agent runtime: Agent class, agentLoop, steering/follow-up queues, event subscription |
| `pi-coding-agent` | Main CLI: interactive session, extension system, skills, prompt templates, model registry |
| `pi-tui` | Terminal UI with differential rendering and synchronized output (CSI 2026) |
| `pi-mom` | Slack bot using pi as SDK |
| `pi-pods` | vLLM pod management |
| `pi-web-ui` | React/lit web components with IndexedDB storage |

---

## Agent Core (`pi-agent-core`)

### Agent State

The `Agent` class holds the following state:

| Property | Type / Values |
|----------|---------------|
| `systemPrompt` | string |
| `model` | string |
| `thinkingLevel` | `off` / `minimal` / `low` / `medium` / `high` / `xhigh` |
| `tools` | registered tool list |
| `messages` | conversation history |
| `isStreaming` | boolean |
| `pendingToolCalls` | tool calls awaiting execution |

### Agent API

```typescript
// Prompt the agent with text or images
await agent.prompt(text);

// Resume without adding a new message
await agent.continue();

// Interrupt tool execution (delivered after current tool, cancels remaining)
agent.steer({ ... });

// Queue work to run after agent finishes current turn
agent.followUp({ ... });

// Subscribe to events
agent.subscribe(event => { ... });
```

### Execution Modes

| Mode | Behavior |
|------|----------|
| `one-at-a-time` | Wait for each response before sending next |
| `all` | Batch: submit all prompts, process responses as they arrive |

---

## Extension System

Extensions are the key differentiator of Pi. They are TypeScript modules that hook into every layer of agent execution.

### Loading Locations

| Scope | Path |
|-------|------|
| Global | `~/.pi/agent/extensions/` |
| Project | `.pi/extensions/` |
| One-off | `pi -e ./path.ts` or `pi -e npm:@foo/bar` |

Auto-hot-reload is available via `/reload`.

### Registration APIs

```typescript
pi.registerTool()       // In-process tool with streaming and custom rendering
pi.registerCommand()    // Slash commands (/mycommand)
pi.registerShortcut()   // Keyboard shortcuts
pi.registerFlag()       // Custom CLI flags
pi.registerProvider()   // Custom model providers with OAuth support
```

### Event System

25+ events across 7 categories. Extensions communicate via the shared `pi.events` bus.

#### Session Events

| Event | Use |
|-------|-----|
| `session_start` | Run setup when session begins |
| `session_shutdown` | Cleanup on exit |

#### Input Events

| Event | Capability |
|-------|-----------|
| `input` | **Block or transform user input before the agent sees it** |

This is unique: no other coding harness exposes this hook. Use it to gate prompts until a condition is met, inject context, or redirect input entirely.

#### Tool Events

| Event | Use |
|-------|-----|
| `tool_call` | Observe or modify a tool call before execution |
| `tool_result` | Observe or modify a tool result |
| `tool_execution_start` | Begin a live progress widget |
| `tool_execution_update` | Stream progress into the widget |
| `tool_execution_end` | Finalize the widget |

Real-time tool streaming is unique to Pi — other harnesses only expose start/end.

#### Bash Events

| Event | Capability |
|-------|-----------|
| `BashSpawnHook` | **Modify command, cwd, or env before the process spawns** |
| `user_bash` | Observe user-initiated bash commands |

#### Agent Lifecycle Events

| Event | Use |
|-------|-----|
| `before_agent_start` | **Inject or modify the system prompt per-turn** |
| `agent_start` | Agent begins processing |
| `agent_end` | Agent finishes turn |
| `turn_start` | Individual turn starts |
| `turn_end` | Individual turn ends |

Dynamic system prompts (`before_agent_start`) allow context-sensitive instructions without restarting the session.

#### Message Events

| Event | Use |
|-------|-----|
| `message_start` | Streaming response begins |
| `message_update` | Streaming token arrives |
| `message_end` | Response complete |

#### Compaction Events

| Event | Use |
|-------|-----|
| `session_before_compact` | Intercept before compaction |
| `session_compact` | Post-compaction hook |

#### Branching Events

| Event | Use |
|-------|-----|
| `session_before_fork` | Before branch creation |
| `session_fork` | After branch creation |
| `session_before_switch` | Before switching branches |
| `session_switch` | After switching branches |
| `session_before_tree` | Before tree navigation |
| `session_tree` | After tree navigation |

#### Model / Context Events

| Event | Capability |
|-------|-----------|
| `model_select` | Observe or intercept model selection |
| `context` | **Receive a deep copy of all messages; filter or prune before submission** |

Context manipulation is powerful: trim old tool results, inject summaries, or redact sensitive data on every turn.

### State Persistence

Extensions can persist custom data across restarts:

```typescript
pi.appendEntry({ type: "custom", data: { ... } });
```

Custom entries are stored in the session JSONL and survive process restarts.

---

## Capabilities Unique to Pi

These features are not available in other coding harnesses (Claude Code, Cursor, Aider, etc.):

| Capability | Mechanism |
|-----------|-----------|
| Input interception | `input` event — block/transform prompts before agent sees them |
| Dynamic system prompts | `before_agent_start` — inject per-turn without restart |
| Live tool streaming | `tool_execution_start/update/end` — real-time progress widgets |
| Bash process interception | `BashSpawnHook` — modify command/cwd/env before spawn |
| Context window manipulation | `context` event — filter/prune messages before API call |
| Session branching | JSONL tree with O(1) fork via `parentId` |
| Inter-extension communication | Shared `pi.events` bus |
| State persistence | `pi.appendEntry()` survives restarts |

---

## Built-in Tools

Pi ships with a deliberately minimal toolset (~200 token system prompt):

| Tool | Description |
|------|-------------|
| `read` | File reading with truncation (head/tail/middle) |
| `write` | File creation and overwriting |
| `edit` | Multi-line editing with unified diff |
| `bash` | Shell execution with output capture |
| `find` | File searching (optional, enable via `--tools`) |
| `grep` | Regex text search (optional, enable via `--tools`) |
| `ls` | Directory listing |

### Deliberate Omissions

Pi intentionally excludes the following. Build them via extensions or packages if needed:

| Feature | Rationale |
|---------|-----------|
| MCP support | 7-14k token overhead per integration |
| Built-in sub-agents | Use tmux, extensions, or packages instead |
| Permission popups | Run in container or build custom flows |
| Plan mode | Write plans to files, or build via extensions |
| Built-in to-dos | Use TODO.md, or build custom |

---

## Model System

20+ providers supported. Authentication via API keys or OAuth.

### Default Models by Provider

| Provider | Default Model |
|----------|--------------|
| Anthropic | claude-opus-4-6 |
| OpenAI | gpt-5.1-codex |
| Google | gemini-2.5-pro |

### Other Supported Providers

Azure, Bedrock, Mistral, Groq, Cerebras, xAI, Hugging Face, Kimi, MiniMax, OpenRouter, Ollama, and more.

### Model Selection

| Method | How |
|--------|-----|
| During session | `/model` command or Ctrl+L |
| Cycle favorites | Ctrl+P |
| Custom providers | `models.json` or extensions via `pi.registerProvider()` |

---

## Session Management

Sessions are stored as an append-only JSONL tree.

### Entry Types

| Type | Purpose |
|------|---------|
| `SessionMessageEntry` | User/assistant messages |
| `ToolCallEvent` | Tool invocation record |
| `ToolResultEvent` | Tool output record |
| `CompactionEntry` | Summary of compacted history |
| `ModelChangeEntry` | Mid-session model switch |
| `CustomEntry` | Extension-defined data |
| `BranchSummaryEntry` | Branch metadata |

### Branching

Each entry has an `id` and optional `parentId`. Branching is O(1) — navigate to any point in history with `/tree` and continue from there. This creates a new branch without copying data.

### Compaction

| Trigger | Method |
|---------|--------|
| Manual | `/compact` |
| Automatic | On context overflow |

Compaction is lossy (summarization), but the full JSONL history is preserved. Hooks `session_before_compact` and `session_compact` allow custom handling.

### Export

| Command | Output |
|---------|--------|
| `/export` | HTML file |
| `/share` | GitHub Gist |

---

## Operating Modes

| Mode | Invocation | Use Case |
|------|-----------|----------|
| Interactive | `pi` | Full TUI with editor, messages, model/thinking selectors |
| Print | `pi -p "prompt"` | One-shot, output to stdout |
| JSON | `--mode json` | Structured event stream for parsing |
| RPC | JSON protocol over stdin/stdout | Non-Node integrations |
| SDK | `createAgentSession()` | Embed Pi in Node.js applications |

---

## Skills System

Skills are Markdown files with YAML frontmatter. They inject documentation or instructions into the system prompt.

| Location | Scope |
|----------|-------|
| `~/.pi/agent/skills/` | Global |
| `.pi/skills/` | Project |

Invoke with `/skill:name` in the session.

---

## Prompt Templates

Markdown files available as slash commands during a session.

| Location | Scope |
|----------|-------|
| `~/.pi/agent/prompts/` | Global |
| `.pi/prompts/` | Project |

Invoke with `/templatename`.

---

## Configuration

Two-level configuration: global overridden by project.

| File | Scope |
|------|-------|
| `~/.pi/agent/settings.json` | Global |
| `.pi/settings.json` | Project |

Configuration categories: model/thinking, compaction, UI, retry.

---

## .pi Directory Structure

```
.pi/
├── extensions/          # Project-local TypeScript extensions
├── prompts/             # Prompt template files (.md)
├── skills/              # Skill files with YAML frontmatter
├── settings.json        # Project-level config
├── keybindings.json     # Custom keyboard shortcuts
└── (other custom dirs)
```

---

## Package System

Packages bundle extensions, skills, prompts, and themes into installable units.

```bash
# Install from npm
pi install npm:@foo/pi-tools

# Install from git
pi install git:github.com/user/repo

# Test without installing
pi -e npm:@foo/bar
```

---

## AGENTS.md

Pi's equivalent of Claude Code's `CLAUDE.md`. Project instructions loaded from:
- `~/.pi/agent/` (global)
- Parent directories (walked upward)
- Current working directory

---

## Comparison with Claude Code

| Feature | Pi | Claude Code |
|---------|----|----|
| System prompt injection | Per-turn via `before_agent_start` event | Static CLAUDE.md |
| Input interception | Yes (`input` event) | No |
| Tool streaming | Yes (start/update/end events) | No |
| Bash interception | Yes (`BashSpawnHook`) | Via hooks (pre-execution only) |
| Context pruning | Yes (`context` event) | No |
| Session branching | Yes (JSONL tree, O(1)) | No |
| MCP support | No (by design) | Yes |
| Sub-agents | Via extensions/tmux | Native |
| Permission system | Build your own | Built-in allow/deny |
| Tool count (default) | 4-7 (~200 token overhead) | 20+ (larger prompt) |
| Extension language | TypeScript | TypeScript |
| Config file | AGENTS.md | CLAUDE.md |

---

## Orchestrating Agents Within Pi

Pi does not have built-in sub-agents. Patterns for multi-agent workflows:

### Pattern 1: tmux Panes

Launch multiple `pi` sessions in tmux panes. Use the bash tool in one session to write files that another reads. Coordinate via shared files or a message queue in the filesystem.

### Pattern 2: Extension-Based Spawning

Write an extension that uses `pi.registerTool()` to spawn child processes (including other `pi` instances in `--mode json` or RPC mode). Parse the event stream to extract results.

```typescript
// Conceptual: spawn a pi subprocess and collect output
pi.registerTool({
  name: "delegate",
  async execute({ prompt }) {
    const result = await runPiSubprocess(prompt);
    return result;
  }
});
```

### Pattern 3: RPC Mode Integration

Pi's RPC mode exposes a JSON protocol over stdin/stdout. A parent process (Node.js app or script) can manage multiple Pi instances as worker agents, routing tasks and collecting results programmatically via `createAgentSession()`.

### Pattern 4: SDK Embedding

```typescript
import { createAgentSession } from "@mariozechner/pi-coding-agent";

const session = await createAgentSession({ model: "claude-opus-4-6" });
await session.agent.prompt("Implement the feature in src/");
```

Use this to build orchestrators that spawn, steer, and collect results from multiple agents in a single Node.js process.

### Coordination Primitives Available

| Primitive | How |
|-----------|-----|
| Steering | `agent.steer()` — interrupt mid-execution |
| Follow-up | `agent.followUp()` — queue next task |
| Events | `agent.subscribe()` — observe all agent activity |
| Persistence | `pi.appendEntry()` — share state across sessions |
| Context manipulation | `context` event — inject orchestrator messages |
