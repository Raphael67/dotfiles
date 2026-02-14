---
name: claude-expert
description: Expert in Claude prompting, skill creation, hooks management, MCP configuration, and sub-agents. Use when writing prompts, creating Claude Code skills, configuring hooks, setting up MCP servers, creating custom sub-agents, or asking about Claude Code architecture.
user-invokable: true
argument-hint: [self-update]
---

# Claude Expert Skill

Expert guidance for Claude prompting techniques, Claude Code extensibility, and agent architecture.

## Quick Reference

| Topic | File | Use When |
|-------|------|----------|
| Prompting | [PROMPTING.md](PROMPTING.md) | Writing effective prompts, XML tags, CoT, few-shot |
| Skills | [SKILLS.md](SKILLS.md) | Creating or editing Claude Code skills |
| Workflows | [WORKFLOWS.md](WORKFLOWS.md) | Building multi-step workflow prompts |
| Commands | [COMMANDS.md](COMMANDS.md) | Creating /commands for quick invocation |
| Hooks | [HOOKS.md](HOOKS.md) | Setting up PreToolUse, validation, notifications |
| MCP | [MCP.md](MCP.md) | Adding MCP servers, tools, resources |
| Sub-agents & Teams | [SUBAGENTS.md](SUBAGENTS.md) | Custom agents, Task tool, agent teams, orchestration |
| Status Lines | [STATUS-LINES.md](STATUS-LINES.md) | Custom terminal status displays, context bars |
| Output Styles | [OUTPUT-STYLES.md](OUTPUT-STYLES.md) | Response formatting, GenUI, custom styles |

## Argument Routing

**If $ARGUMENTS is "self-update"**: Read and execute [cookbook/self-update.md](cookbook/self-update.md)

**Otherwise**: Continue with normal skill guidance below.

## Core Principles

### Prompting
- Use **XML tags** for structure (`<context>`, `<instructions>`, `<constraints>`)
- Be **explicit** rather than implicit
- Specify **format** to get formatted output
- Provide **examples** for complex tasks

### Skills
- Skills = markdown files that extend Claude's capabilities
- Description is **critical** for auto-discovery
- Keep SKILL.md < 500 lines, split into reference files
- Use semantic XML tags in content
- **MANDATORY**: Every skill with external resources must include a self-update cookbook (see SKILLS.md Self-Update Pattern)

### Hooks
- 13 hook events covering the full lifecycle (Setup, SessionStart, UserPromptSubmit, PreToolUse, PostToolUse, etc.)
- Setup hook (`claude --init`) for repo initialization and dependency installation
- Can `block`, `allow`, or `ask` for confirmation
- Exit codes: 0=allow, 2=block, JSON output for decisions
- `CLAUDE_ENV_FILE` for persisting env vars (Setup/SessionStart)

### MCP
- Servers defined in `~/.claude/.mcp.json`
- Provide external tools and resources
- Use stdio, SSE, or HTTP transport

### Sub-agents & Agent Teams
- **Sub-agents**: Task tool, isolated context, report back to parent
- **Agent teams** (experimental): multiple independent sessions, shared task list, direct messaging
- Default to single agents; use multi-agent only for context protection, parallelization, or specialization
- Custom agents in `.claude/agents/` or `~/.claude/agents/`

### Workflows
- Variables at top for constants
- Instructions for rules/constraints
- Step-by-step workflow section
- Report template at end

### Commands
- Quick-access prompts in `.claude/commands/`
- Can restrict tools and specify model
- Support argument passing

## When to Read Reference Files

**Read PROMPTING.md when:**
- User asks to write a prompt or system message
- Optimizing an existing prompt
- Structuring complex instructions

**Read SKILLS.md when:**
- Creating a new skill
- Editing skill YAML frontmatter
- Debugging skill discovery
- Understanding cookbook/prompts patterns

**Read WORKFLOWS.md when:**
- Building multi-step workflow prompts
- Defining variables and instructions
- Creating orchestrated workflows
- Handling parallel execution

**Read COMMANDS.md when:**
- Creating /command shortcuts
- Setting up prime or install commands
- Understanding command vs skill differences

**Read HOOKS.md when:**
- Setting up security validation
- Adding notifications or logging
- Configuring PreToolUse patterns
- Setting up `claude --init` (Setup hook)
- Configuring SessionStart context injection
- Understanding hook-specific flow control and blocking

**Read MCP.md when:**
- Adding external tool servers
- Configuring MCP resources
- Troubleshooting MCP connections

**Read SUBAGENTS.md when:**
- Creating custom agents
- Configuring agent tools/permissions
- Understanding Task tool options
- Setting up parallel agent execution
- Managing multi-agent safety
- Using agent teams (multi-session orchestration)
- Deciding between subagents vs agent teams
- Understanding multi-agent orchestration principles
- Building team-based validation (builder/validator pattern)
- Understanding the meta-agent pattern

**Read STATUS-LINES.md when:**
- Creating custom terminal status displays
- Showing context window usage, cost, tokens
- Integrating session data into status lines
- Adding agent naming or custom metadata

**Read OUTPUT-STYLES.md when:**
- Creating custom response formatting
- Setting up GenUI (HTML generation) style
- Understanding output style configuration
- Building domain-specific output formats
