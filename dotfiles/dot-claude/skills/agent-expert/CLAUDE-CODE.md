# Claude Code Internal Architecture Reference

> **Scope**: Internal architecture — tool system, task system, coordinator, query engine, context pipeline, feature flags.
> **Cross-reference**: For practical agent creation, Task tool usage, custom agents, and team configuration, see `claude-expert/SUBAGENTS.md`.

---

## 1. Architecture Overview

| Attribute | Value |
|-----------|-------|
| Codebase size | ~1,900 files, 512,000+ lines TypeScript |
| Runtime | Bun |
| UI framework | React + Ink (terminal UI) |
| CLI framework | Commander.js |
| Validation | Zod v4 |
| Search backend | ripgrep (embedded bfs/ugrep when available) |
| Protocols | MCP (Model Context Protocol), LSP |
| API client | Anthropic SDK |
| Telemetry | OpenTelemetry + gRPC |
| Auth | OAuth 2.0, JWT, macOS Keychain |

### Source Directory Layout

```
src/
├── main.tsx           # CLI entrypoint
├── commands.ts        # Slash command registry (~50 commands)
├── tools.ts           # Tool registry (~40 tools)
├── Tool.ts            # Tool type definitions and interfaces
├── QueryEngine.ts     # Core LLM query engine (~46K lines)
├── context.ts         # Context collection logic
├── cost-tracker.ts    # Token cost tracking
├── commands/          # Slash command implementations
├── tools/             # Tool implementations
├── components/        # Ink UI components (~140)
├── coordinator/       # Multi-agent coordination
├── plugins/           # Plugin system
├── skills/            # Skill workflows
├── bridge/            # IDE bridge (VS Code, JetBrains)
├── tasks/             # Task management
├── state/             # State management
├── memdir/            # Persistent memory
└── query/             # Query pipeline
```

---

## 2. Tool System

### Tool Interface (Tool.ts)

Every tool implements this interface:

| Field / Method | Type | Description |
|----------------|------|-------------|
| `inputSchema` | Zod schema | Parameter validation; controls what the model can pass |
| `call()` | async function | Core execution logic |
| `checkPermissions()` | function | Tool-specific permission gate; called before `call()` |
| `isConcurrencySafe()` | boolean | Whether this tool can run in parallel with others |
| `isReadOnly()` | boolean | Whether the tool modifies state |
| `isDestructive()` | boolean | Flags irreversible operations; triggers confirmation prompts |
| `interruptBehavior()` | `'cancel'` or `'block'` | Behavior when user sends a new message mid-execution |
| `shouldDefer` | boolean | Requires ToolSearch before first use (deferred tools) |
| `maxResultSizeChars` | number | Result size budget before results are persisted to disk |
| `toAutoClassifierInput()` | function | Provides input for the security auto-classifier |
| `preparePermissionMatcher()` | function | Hook pattern matching for permission rules |

### Tool Assembly Pipeline

```
getAllBaseTools()          # Returns all built-in tools
    ↓
getTools()                # Filters by current permission context
    ↓
assembleToolPool()        # Merges built-in + MCP tools
                          # Sorted for prompt-cache stability
```

---

## 3. Complete Tool Registry

### Core Tools (always available)

| Tool | Description |
|------|-------------|
| `AgentTool` | Spawn sub-agents (Task tool) |
| `BashTool` | Shell command execution |
| `FileReadTool` | Read file contents |
| `FileEditTool` | Edit files (diff-based) |
| `FileWriteTool` | Write/create files |
| `GlobTool` | File pattern matching (disabled when embedded bfs available) |
| `GrepTool` | Content search (disabled when embedded ugrep available) |
| `NotebookEditTool` | Jupyter notebook editing |
| `WebFetchTool` | HTTP fetch |
| `WebSearchTool` | Web search |
| `TodoWriteTool` | Task tracking (legacy todo list) |
| `SkillTool` | Skill execution |
| `AskUserQuestionTool` | Interactive user prompts |
| `EnterPlanModeTool` | Enter plan mode |
| `ExitPlanModeV2Tool` | Exit plan mode |
| `SendMessageTool` | Inter-agent messaging |
| `TaskOutputTool` | Emit structured task output |
| `TaskStopTool` | Terminate current task |
| `BriefTool` | Switch to brief output mode |
| `ListMcpResourcesTool` | List available MCP resources |
| `ReadMcpResourceTool` | Read an MCP resource |
| `ToolSearchTool` | Discover and load deferred tools |

### Task Management Tools (when TodoV2 enabled)

| Tool | Description |
|------|-------------|
| `TaskCreateTool` | Create a new tracked task |
| `TaskGetTool` | Retrieve task by ID |
| `TaskUpdateTool` | Update task status or metadata |
| `TaskListTool` | List all tasks |

### Agent Teams (when AGENT_SWARMS enabled)

| Tool | Description |
|------|-------------|
| `TeamCreateTool` | Create a named agent team |
| `TeamDeleteTool` | Disband an agent team |

### Worktree Tools (when worktree mode enabled)

| Tool | Description |
|------|-------------|
| `EnterWorktreeTool` | Enter a git worktree context |
| `ExitWorktreeTool` | Exit a git worktree context |

### Feature-Flagged Tools

| Tool | Feature Flag | Description |
|------|-------------|-------------|
| `SleepTool` | PROACTIVE / KAIROS | Wait or enter proactive idle mode |
| `CronCreateTool` | AGENT_TRIGGERS | Create scheduled trigger |
| `CronDeleteTool` | AGENT_TRIGGERS | Delete scheduled trigger |
| `CronListTool` | AGENT_TRIGGERS | List scheduled triggers |
| `RemoteTriggerTool` | AGENT_TRIGGERS_REMOTE | Remote-initiated triggers |
| `MonitorTool` | MONITOR_TOOL | MCP-based monitoring |
| `WebBrowserTool` | WEB_BROWSER_TOOL | Browser automation |
| `WorkflowTool` | WORKFLOW_SCRIPTS | Workflow script execution |
| `SnipTool` | HISTORY_SNIP | Trim conversation history |
| `ListPeersTool` | UDS_INBOX | Unix domain socket peer discovery |
| `OverflowTestTool` | OVERFLOW_TEST_TOOL | Context overflow testing |
| `CtxInspectTool` | — | Context inspection (debugging) |
| `TerminalCaptureTool` | TERMINAL_PANEL | Terminal output capture |

### Ant-Only Tools (internal Anthropic)

| Tool | Notes |
|------|-------|
| `REPLTool` | Interactive REPL |
| `SuggestBackgroundPRTool` | PR suggestion |
| `ConfigTool` | Internal config |
| `TungstenTool` | Internal tooling |
| `SendUserFileTool` | File delivery (KAIROS) |
| `PushNotificationTool` | Push notifications (KAIROS) |
| `SubscribePRTool` | GitHub PR subscription (KAIROS) |

---

## 4. Task System

### Task Types

| Type | ID Prefix | Description |
|------|-----------|-------------|
| `local_bash` | `b` | Shell command execution |
| `local_agent` | `a` | Local sub-agent instance |
| `remote_agent` | `r` | Remote agent instance |
| `in_process_teammate` | `t` | In-process team member |
| `local_workflow` | `w` | Workflow script execution |
| `monitor_mcp` | `m` | MCP-based monitoring task |
| `dream` | `d` | Dream/idle background task |

### Task Lifecycle

```
pending → running → completed
                 → failed
                 → killed
```

### TaskStateBase Fields

| Field | Description |
|-------|-------------|
| `id` | Unique task identifier (type-prefixed) |
| `type` | One of the 7 task types above |
| `status` | Current lifecycle state |
| `description` | Human-readable task description |
| `toolUseId` | ID of the tool use that spawned this task |
| `startTime` | Task start timestamp |
| `endTime` | Task end timestamp (null if running) |
| `outputFile` | Path to output file (disk persistence) |
| `outputOffset` | Read offset for incremental output |
| `notified` | Whether completion notification was sent |

### Task Implementations

- `LocalShellTask` — wraps `local_bash`
- `LocalAgentTask` — wraps `local_agent`
- `RemoteAgentTask` — wraps `remote_agent`
- `DreamTask` — wraps `dream`
- `LocalWorkflowTask` — wraps `local_workflow`
- `MonitorMcpTask` — wraps `monitor_mcp`

---

## 5. Feature Flags

Feature flags are resolved at compile time via `bun:bundle`. They cannot be toggled at runtime.

| Flag | Effect |
|------|--------|
| `PROACTIVE` | Proactive agent behavior; enables SleepTool |
| `KAIROS` | Mobile/desktop app features; push notifications; GitHub webhooks |
| `BRIDGE_MODE` | IDE bridge for VS Code and JetBrains |
| `DAEMON` | Remote control server |
| `VOICE_MODE` | Voice input support |
| `AGENT_TRIGGERS` | Scheduled (cron) triggers |
| `AGENT_TRIGGERS_REMOTE` | Remote-initiated triggers |
| `MONITOR_TOOL` | MCP monitoring tool |
| `COORDINATOR_MODE` | Multi-agent coordinator |
| `WEB_BROWSER_TOOL` | Browser automation tool |
| `WORKFLOW_SCRIPTS` | Workflow engine |
| `HISTORY_SNIP` | History trimming |
| `UDS_INBOX` | Unix domain socket messaging between peers |
| `FORK_SUBAGENT` | Subagent forking |
| `BUDDY` | Companion sprite feature |
| `CONTEXT_COLLAPSE` | Automatic context management |
| `TERMINAL_PANEL` | Terminal capture panel |
| `MCP_SKILLS` | MCP-provided skills |
| `EXPERIMENTAL_SKILL_SEARCH` | Skill search |
| `ULTRAPLAN` | Advanced planning mode |
| `TORCH` | Torch feature |
| `OVERFLOW_TEST_TOOL` | Context overflow testing tool |
| `KAIROS_BRIEF` | Brief output mode (Kairos sub-feature) |
| `KAIROS_PUSH_NOTIFICATION` | Push notifications (Kairos sub-feature) |
| `KAIROS_GITHUB_WEBHOOKS` | GitHub webhook integration (Kairos sub-feature) |
| `AGENT_SWARMS` | Agent team creation (TeamCreate/TeamDelete tools) |

---

## 6. Context System (context.ts)

The context pipeline assembles the system prompt from multiple sources:

| Function | Description |
|----------|-------------|
| `getGitStatus()` | Memoized git snapshot: branch name, main branch, working tree status, recent log, git user. Truncated at 2,000 chars. |
| `getUserContext()` | User-level context (home directory, shell, env) |
| `getSystemContext()` | System-level context; cache invalidated on injection changes |
| `getClaudeMds()` | Hierarchical CLAUDE.md loading (global → project → subdir) |
| `getMemoryFiles()` | Auto-memory file loading from `memdir/` |

System prompt injection (ant-only debugging): allows injecting additional content into the system prompt at startup without modifying source files.

---

## 7. Cost Tracking (cost-tracker.ts)

Per-model usage is tracked with the following shape:

```typescript
{
  inputTokens: number,
  outputTokens: number,
  cacheReadInputTokens: number,
  cacheCreationInputTokens: number,
  webSearchRequests: number,
  costUSD: number,
}
```

| Behavior | Description |
|----------|-------------|
| Session-level persistence | Costs written to project config on disk |
| Session resume | Prior session costs restored when resuming |
| OpenTelemetry counters | Cost and token metrics emitted as OTel counters |
| Advisor tracking | Separate tracking for `tengu_advisor` model usage |

---

## 8. Command System (commands.ts)

~50+ slash commands organized by category:

| Category | Commands |
|----------|----------|
| Session | `compact`, `resume`, `session`, `share`, `export`, `clear` |
| Navigation | `diff`, `files`, `branch`, `rewind` |
| Model | `model`, `fast`, `effort` |
| Config | `config`, `permissions`, `hooks`, `keybindings`, `mcp`, `plugin` |
| Info | `cost`, `status`, `usage`, `stats`, `insights`, `doctor` |
| Agent | `agents`, `tasks`, `plan` |
| Identity | `color`, `theme`, `vim`, `statusline`, `output-style` |
| Auth | `login`, `logout` |
| App | `desktop`, `mobile`, `ide`, `bridge` |
| Extended | `skills`, `memory`, `review`, `security-review`, and others |

---

## 9. Permission System

### ToolPermissionContext

| Field | Description |
|-------|-------------|
| `mode` | Active permission mode (see below) |
| `additionalWorkingDirectories` | Extra directories the agent can access |
| `alwaysAllowRules` | Patterns that bypass confirmation |
| `alwaysDenyRules` | Patterns that are unconditionally blocked |
| `alwaysAskRules` | Patterns that always require confirmation |

### Permission Modes

| Mode | Behavior |
|------|----------|
| `default` | Normal confirmation prompts for destructive operations |
| `plan` | Read-only; no writes or shell execution |
| `acceptEdits` | Auto-accepts file edits, confirms shell |
| `dontAsk` | Skips most confirmation prompts |
| `bypassPermissions` | Bypasses all permission checks (headless/CI use) |

### Permission Enforcement Pipeline

```
Tool input received
    ↓
toAutoClassifierInput()     # Extract security-relevant fields
    ↓
Auto-classifier             # Pattern-match against deny/allow/ask rules
    ↓
checkPermissions()          # Tool-level permission logic
    ↓
Denial tracking             # Count denials; fall back to prompting if threshold exceeded
    ↓
Execution or block
```

Pre-plan mode state is preserved so the prior mode is restored on exit.

---

## 10. Bridge System (src/bridge/)

The bridge enables two-way communication with IDEs (VS Code, JetBrains):

| Aspect | Detail |
|--------|--------|
| Communication | Bidirectional message protocol over local socket |
| Permission callbacks | IDE can approve/deny permission prompts |
| Authentication | JWT tokens |
| Session control | IDE can start, stop, and observe sessions |
| Command filtering | Commands classified as remote-safe vs. bridge-safe before execution |

Bridge mode is enabled at compile time via the `BRIDGE_MODE` feature flag.

---

## Key Decision Points for Agent Workflows

When designing agent workflows, the following architectural constraints are relevant:

- **Tool concurrency**: Only tools where `isConcurrencySafe()` returns true can safely run in parallel. BashTool is not concurrency-safe by default.
- **Context size**: `maxResultSizeChars` limits inline result size. Large results are persisted to disk and referenced by path — agents should be prepared to read output files rather than inline results.
- **Deferred tools**: Tools with `shouldDefer = true` require a ToolSearch call before first use. The tool schema is not available in the initial prompt.
- **Task output persistence**: Task results are written to `outputFile` incrementally; `outputOffset` tracks read position for streaming.
- **Feature flag availability**: Not all tools exist in all builds. Agent prompts that reference feature-flagged tools (e.g., CronCreateTool, WebBrowserTool) will fail silently if the flag is not set.
- **Permission mode propagation**: Sub-agents inherit the parent's permission context, including the active mode and allow/deny rules.
