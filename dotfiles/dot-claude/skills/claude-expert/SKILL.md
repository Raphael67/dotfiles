---
name: claude-expert
description: Expert in Claude prompting, skill creation, hooks management, MCP configuration, and sub-agents. Use when writing prompts, creating Claude Code skills, configuring hooks, setting up MCP servers, creating custom sub-agents, or asking about Claude Code architecture.
user-invocable: true
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
| Sub-agents | [SUBAGENTS.md](SUBAGENTS.md) | Creating custom agents, Task tool config |

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

### Hooks
- PreToolUse hooks validate before execution
- Can `block`, `allow`, or `ask` for confirmation
- Exit codes: 0=allow, 2=block, JSON output for ask

### MCP
- Servers defined in `~/.claude/.mcp.json`
- Provide external tools and resources
- Use stdio, SSE, or HTTP transport

### Sub-agents
- Defined in `.claude/agents/` or `~/.claude/agents/`
- YAML frontmatter + markdown instructions
- Can specify model, tools, allowed-tools

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
