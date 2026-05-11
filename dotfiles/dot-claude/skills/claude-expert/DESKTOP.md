# Claude Desktop App

Reference for Claude Desktop application features and capabilities.

## Overview

Claude Desktop is the native macOS/Windows app for interacting with Claude models. It extends the claude.ai web experience with native OS integration: scheduled tasks, local MCP server support, and tighter system access for desktop workflows.

## Key Features

### Conversations
- Standard chat interface with Claude models (Opus 4.7, Sonnet 4.6, Haiku 4.5)
- File and image uploads
- Project-based conversations with persistent context
- Artifacts pane for code, documents, and interactive content with side-by-side preview

### MCP Integration
- MCP servers configured in `~/Library/Application Support/Claude/claude_desktop_config.json` (macOS) or `%APPDATA%\Claude\claude_desktop_config.json` (Windows)
- Servers run as local processes managed by the Desktop app
- Different config from Claude Code: Desktop MCPs are app-scoped; Claude Code MCPs are project/session-scoped

### Scheduled Tasks
- Schedule prompts to run automatically on a recurring cadence
- Useful for recurring reports, monitoring runs, periodic data refreshes
- Desktop-only — Claude Code uses skills like `/loop` or `/schedule` for similar effects

### Cowork Mode
- Collaborative mode for longer-running, persistent sessions
- Shared context that survives across reopens

### Claude Design (Anthropic Labs, 2026-04-17)
- New collaborative visual creation product
- Generates polished visual work: designs, prototypes, slides, one-pagers
- Complements code/text workflows with a visual-first surface
- Released as part of Anthropic Labs experimental products

### Claude for Creative Work (2026-04-28)
- Initiative expanding Claude into creative applications
- Targets workflows beyond pure coding/writing — design, narrative, visual ideation

## Recent Anthropic Announcements (since 2026-04-16)

| Date | Announcement | Notes |
|------|--------------|-------|
| 2026-04-16 | Claude Opus 4.7 released | Stronger coding, agents, vision, multi-step tasks. Opus model ID `claude-opus-4-7`. |
| 2026-04-17 | Claude Design (Anthropic Labs) | Visual creation product — designs, prototypes, slides |
| 2026-04-28 | Claude for Creative Work | Expanded creative-application capabilities |
| 2026-05-06 | Higher usage limits | Anthropic increased usage limits for Claude subscribers |
| 2026-05-06 | SpaceX compute deal | Anthropic announced compute infrastructure partnership with SpaceX |
| 2026-05-05 | Agents for financial services | Specialized agent offering for financial services industry workflows |

## Sources

- Download: https://www.anthropic.com/download
- News (Anthropic): https://www.anthropic.com/news
- Changelog (claude.ai): https://claude.ai/changelog *(currently 403 to non-authenticated fetchers)*
- Support: https://support.claude.com/en/collections/4560928-claude-desktop *(redirected from anthropic.com domain)*
