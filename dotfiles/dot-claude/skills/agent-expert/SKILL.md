---
name: agent-expert
description: Expert in AI coding agent harnesses (Claude Code, Pi, OpenCode, OpenRouter), multi-agent orchestration, model routing, team architecture, and cross-harness workflows. Use when managing harnesses, agents, models, providers, teams, orchestration, coordinator mode, openrouter, open-code, pi-mono, multi-agent workflows, or agent architecture decisions.
user-invokable: true
argument-hint: [self-update]
model: opus
---

# Agent Expert Skill

Comprehensive reference for AI coding agent harnesses and multi-agent orchestration.

## Quick Reference

| Topic | File | Use When |
|-------|------|----------|
| Claude Code Internals | [CLAUDE-CODE.md](CLAUDE-CODE.md) | CC architecture, tool system, task types, coordinator, feature flags |
| Pi Agent | [PI.md](PI.md) | Pi extensions, events, SDK, session trees, multi-provider |
| OpenCode | [OPENCODE.md](OPENCODE.md) | OC agents, plugins, providers, permissions, LSP |
| OpenRouter | [OPENROUTER.md](OPENROUTER.md) | Model routing, API, fallbacks, agent integrations |
| Cross-Harness Comparison | [COMPARISON.md](COMPARISON.md) | Feature matrices, decision trees, gap analysis |
| Orchestration Patterns | [ORCHESTRATION.md](ORCHESTRATION.md) | Multi-agent patterns, team topologies, safety |
| Models & Cost | [MODELS.md](MODELS.md) | Model selection, cost tiers, thinking levels, context windows |

## Cookbooks (Ready-to-Use Templates)

| Cookbook | File | Contents |
|---------|------|----------|
| CC Teams | [cookbook/cc-teams.md](cookbook/cc-teams.md) | Agent team configurations for Claude Code |
| Pi Extensions | [cookbook/pi-extensions.md](cookbook/pi-extensions.md) | Extension templates (dispatcher, chain, meta-agent) |
| OC Agents | [cookbook/oc-agents.md](cookbook/oc-agents.md) | OpenCode agent definitions |
| Cross-Harness Workflows | [cookbook/orchestration.md](cookbook/orchestration.md) | Workflow recipes for each harness |
| Self-Update | [cookbook/self-update.md](cookbook/self-update.md) | Update skill from web + repo sources |

## Argument Routing

**If $ARGUMENTS is "self-update"**: Read and execute [cookbook/self-update.md](cookbook/self-update.md)

**Otherwise**: Continue with normal guidance below.

## Relationship to claude-expert

This skill focuses on **cross-harness knowledge, architecture, and orchestration patterns**. For Claude Code-specific agent creation (Task tool, custom agents, teams, hooks), defer to **claude-expert/SUBAGENTS.md** which covers practical CC agent workflows in depth.

## Core Principles

### Claude Code
- Batteries-included enterprise harness (~40 tools, ~50 commands)
- Native sub-agents (Agent tool), agent teams (TeamCreate), coordinator mode
- 7 task types: local_bash, local_agent, remote_agent, in_process_teammate, local_workflow, monitor_mcp, dream
- Feature-flagged capabilities (PROACTIVE, KAIROS, COORDINATOR_MODE, etc.)
- Anthropic-first, gateway workaround for other providers

### Pi
- Minimal extensible harness (4-7 tools, ~200 token system prompt)
- 25+ extension events with full runtime access (TypeScript in-process)
- Unique: input interception, dynamic system prompts, tool streaming, bash spawn hooks, context manipulation
- 20+ providers native, 324 models, session tree branching
- Philosophy: "Adapt pi to your workflows"

### OpenCode
- Open-source CC alternative (MIT), 75+ providers via Vercel AI SDK
- 4 agent types (build, plan, general, explore) + custom agents
- Native LSP support, SKILL.md compatible with Claude Code
- Client/server architecture, SQLite sessions, Tauri desktop app

### OpenRouter
- Model routing gateway with hundreds of models
- Automatic fallbacks, Auto Exacto, Auto Router
- Model variants: :free, :extended, :thinking, :online, :nitro
- OpenAI SDK compatible, agent SDK for multi-turn workflows

## When to Read Reference Files

**Read CLAUDE-CODE.md when:**
- Understanding CC internals (tool registry, QueryEngine, context pipeline)
- Working with feature flags or coordinator mode
- Analyzing CC's task system or permission architecture
- Debugging tool behavior or cost tracking

**Read PI.md when:**
- Building Pi extensions or understanding the event system
- Configuring Pi providers, models, or session management
- Working with Pi's SDK, RPC, or print modes
- Understanding Pi's extension capabilities vs other harnesses

**Read OPENCODE.md when:**
- Configuring OpenCode agents, providers, or permissions
- Building custom tools or plugins for OpenCode
- Understanding OC's Effect-based architecture
- Working with OC's LSP integration or session management

**Read OPENROUTER.md when:**
- Setting up model routing or multi-provider access
- Configuring fallbacks, cost optimization, or observability
- Integrating OpenRouter with coding agents
- Comparing direct API vs gateway approaches

**Read COMPARISON.md when:**
- Choosing between harnesses for a specific use case
- Understanding capability gaps between harnesses
- Making architecture decisions about agent infrastructure

**Read ORCHESTRATION.md when:**
- Designing multi-agent workflows (any harness)
- Choosing orchestration patterns (lead/worker, builder/validator, etc.)
- Implementing safety patterns for parallel agents
- Scaling agent teams

**Read MODELS.md when:**
- Selecting models for specific tasks or agents
- Optimizing costs across providers
- Understanding thinking/reasoning levels
- Configuring context windows or compaction
