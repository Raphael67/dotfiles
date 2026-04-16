# Claude Code Skills Reference

## What Are Skills?

Skills are markdown files that extend Claude Code's capabilities by providing specialized instructions, context, and patterns for specific domains or tasks.

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard.

## How Skills Work

1. **Startup**: Claude Code loads skill **descriptions** into context so it knows what's available
2. **Discovery**: Claude automatically decides when to use a skill based on description match
3. **Loading**: Full skill content is loaded only when invoked (not at startup)
4. **Execution**: Claude follows the skill's instructions for the task

**Critical**: The description determines if Claude will find and use your skill.

## Directory Structure

### Standard Structure
```
.claude/skills/
└── skill-name/              # Directory (lowercase, hyphens)
    ├── SKILL.md             # Main file (REQUIRED)
    ├── REFERENCE.md         # Additional docs (optional)
    ├── PATTERNS.md          # Code patterns (optional)
    └── scripts/             # Helper scripts (optional)
        └── helper.py
```

### Advanced Structure (Cookbook Pattern)
For complex skills with multiple workflows:
```
.claude/skills/
└── skill-name/
    ├── SKILL.md                 # Main file with decision tree
    ├── patterns.yaml            # Shared configuration (single source of truth)
    ├── cookbook/                # Workflow documentation
    │   ├── install_workflow.md
    │   ├── modify_workflow.md
    │   └── test_workflow.md
    ├── prompts/                 # Reusable prompt templates
    │   ├── build.md
    │   ├── test.md
    │   └── report.md
    ├── examples/                # Progressive disclosure examples
    │   ├── 01_basic_usage.md
    │   ├── 02_advanced_usage.md
    │   └── 03_edge_cases.md
    ├── hooks/                   # Implementation variants
    │   ├── implementation-python/
    │   └── implementation-typescript/
    └── tools/                   # Helper scripts
        └── helper.py
```

### Locations

| Location | Path | Applies to |
|----------|------|------------|
| Enterprise | Managed settings | All users in org |
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin is enabled |

When skills share the same name, higher-priority locations win: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace (no conflicts).

## SKILL.md Format

```yaml
---
name: my-skill-name
description: What the skill does AND when to use it. Include trigger keywords.
user-invocable: false
allowed-tools: Read, Grep, Glob
version: 1.0.0
---

# Skill Title

Instructions and content...
```

## Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | No | Display name. If omitted, uses directory name. Lowercase + hyphens, max 64 chars |
| `description` | Recommended | What + when. **Critical for discovery**. If omitted, uses first paragraph |
| `user-invocable` | No | Set to `false` to hide from `/` menu. Default: `true` |
| `disable-model-invocation` | No | `true` to prevent Claude from auto-loading. Default: `false` |
| `allowed-tools` | No | Restrict available tools (e.g., `Read, Grep, Glob`) |
| `context` | No | Set to `fork` to run in forked subagent context |
| `agent` | No | Agent type when `context: fork` (e.g., `Explore`, `Plan`, custom) |
| `model` | No | Model to use (`sonnet`, `opus`, `haiku`) |
| `hooks` | No | Lifecycle hooks scoped to skill. See Hooks reference |
| `effort` | No | Effort level when skill is active. Overrides session effort. Options: `low`, `medium`, `high`, `max` (Opus 4.6 only) (v2.1.80+) |
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`) |

## Bundled Skills

Claude Code ships with built-in skills available in every session:

| Skill | Description |
|-------|-------------|
| `/simplify` | Reviews recently changed files for code reuse, quality, and efficiency. Spawns 3 parallel review agents |
| `/batch <instruction>` | Orchestrates large-scale parallel changes across a codebase. Decomposes into 5-30 units, each in an isolated git worktree |
| `/debug [description]` | Troubleshoots current Claude Code session by reading debug logs. Toggles debug logging on mid-session (v2.1.71) |
| `/loop [interval] <prompt>` | Runs a prompt repeatedly on an interval (e.g., `/loop 5m check the deploy`). Schedules recurring cron tasks within the session (v2.1.71) |
| `/claude-api` | Loads Claude API reference for your project's language (Python, TypeScript, Java, Go, Ruby, C#, PHP, cURL) + Agent SDK reference. Auto-activates on `anthropic`/`@anthropic-ai/sdk`/`claude_agent_sdk` imports |

## Argument Substitution

Skills support variable substitution patterns:

### Shorthand Syntax (v2.1.19+)
```markdown
## Variables

USER_INPUT: $0          # First argument
OUTPUT_PATH: $1         # Second argument
OPTIONS: $2             # Third argument
```

### Bracket Syntax
```markdown
## Variables

USER_INPUT: $ARGUMENTS[0]
OUTPUT_PATH: $ARGUMENTS[1]
ALL_ARGS: $ARGUMENTS
```

### Session & Skill Variables
- `${CLAUDE_SESSION_ID}` - Current session ID for logging/tracking
- `${CLAUDE_SKILL_DIR}` - Absolute path to the skill's directory (v2.1.69+). Use for referencing bundled scripts/files regardless of CWD

### Dynamic Context Injection
Use shell command output in skills:
```yaml
---
name: context-aware-skill
---

# Recent Changes
!`git log --oneline -5`

Use the commits above for context.
```

## Extended Thinking

Include "ultrathink" anywhere in skill content to enable extended thinking mode:
```yaml
---
name: complex-analyzer
---

ultrathink

Analyze this complex problem thoroughly before responding.
```

## Invocation Control

| Frontmatter | You can invoke | Claude can invoke | Context loading |
|-------------|----------------|-------------------|-----------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context |
| `user-invocable: false` | No | Yes | Description always in context |

## Restrict Skill Access

Control which skills Claude can use via permission rules:
```
# Allow specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

Disable all skills: add `Skill` to deny rules in `/permissions`.

## Skill Path Configuration

Skills in rules/hooks can specify target paths using the `paths:` field. Accepts YAML list of glob patterns (v2.1.85+):

```yaml
---
name: web-developer
paths:
  - "src/**/*.{ts,tsx}"
  - "public/**/*"
---
```

This restricts the skill to only activate when working with files matching those patterns.

## Skill Approval

Skills without additional permissions or hooks are auto-approved. Only skills requesting extra permissions or defining hooks need user approval.

## SKILL.md Sections

A well-structured SKILL.md follows this pattern:

### 1. Variables Section
Define skill-wide constants that can be referenced throughout:

```markdown
## Variables

SKILL_DIR: .claude/skills/my-skill
CONFIG_FILE: SKILL_DIR/config.yaml
TIMEOUT_SECONDS: 3600
DEFAULT_MODEL: sonnet
```

For variables that depend on the user's machine (paths, secrets, preferences), load them from a `.env` file at runtime instead of hardcoding. See [Environment Bootstrap Pattern](#environment-bootstrap-pattern).

### 2. Instructions Section
Core guidance for the skill:

```markdown
## Instructions

- Follow the `Workflow` to complete the task
- Use AskUserQuestion for decision points
- **IMPORTANT**: Never skip validation steps
- All commands must be run from `SKILL_DIR`
```

### 3. Workflow Section
Step-by-step execution flow:

```markdown
## Workflow

### Step 1: Validate Environment
1. Check for required configuration
2. Verify dependencies are installed

### Step 2: Execute Task
1. Perform the main action
2. Handle errors gracefully

### Step 3: Report Results
1. Summarize what was done
2. Provide next steps
```

### 4. Cookbook Section (Decision Tree)
Route to specific workflows based on user intent:

```markdown
## Cookbook

### Installation Pathway
**Trigger phrases**: "install", "setup", "deploy"
**Workflow**: Read and execute [cookbook/install_workflow.md](cookbook/install_workflow.md)

### Modification Pathway
**Trigger phrases**: "modify", "update", "change"
**Workflow**: Read and execute [cookbook/modify_workflow.md](cookbook/modify_workflow.md)

### Direct Command Pathway
**Trigger phrases**: "add X to Y", "block command Z"
**Action**: Execute immediately without prompts - user knows the system
```

### 5. Report Section
Standard output format:

```markdown
## Report

Present the summary:

### Task Complete

**Status**: [Success/Partial/Failed]
**Files Modified**: [list]
**Next Steps**: [recommendations]
```

## Writing Effective Descriptions

The description is **the most important field**. It determines when Claude will find and use your skill.

### Bad Description
```yaml
name: docs-helper
description: Helps with documents
```
Too vague, won't be discovered for relevant tasks.

### Good Description
```yaml
name: pdf-processor
description: Extract text and tables from PDF files, fill forms, merge documents. Use for PDF files, data extraction, or when user mentions PDF, forms, or documents.
```
Specific with clear trigger words.

### Description Formula
```
[What it does] + [Use cases] + [Trigger keywords]
```

## Content Structure

Use XML tags for organization (Claude understands them well):

```yaml
---
name: domain-expert
description: Expert in X domain. Use when working with X, Y, or Z.
---

# Domain Expert Skill

<role>
Define expertise and personality.
</role>

<context>
Background and key domain concepts.
</context>

<constraints>
- Rule 1
- Rule 2
</constraints>

<patterns>
## Pattern Name
```code
Reusable code snippet
```
</patterns>

<examples>
<example>
  <input>User request</input>
  <output>Expected response</output>
</example>
</examples>

<instructions>
Step-by-step workflow.
</instructions>
```

## Reference Files

Split large content into reference files to reduce context usage:

| File | Purpose |
|------|---------|
| `SKILL.md` | Overview, quick start (< 500 lines) |
| `REFERENCE.md` | Detailed API, options |
| `PATTERNS.md` | Code patterns, snippets |
| `MIGRATION.md` | Migration guides |

Reference in SKILL.md:
```markdown
## Reference Files

| File | Use When |
|------|----------|
| [REFERENCE.md](REFERENCE.md) | Need detailed API docs |
| [PATTERNS.md](PATTERNS.md) | Looking for code patterns |
```

## Complete Example

```yaml
---
name: openscad
description: Expert skill for creating and editing OpenSCAD 3D models (.scad). Use for creating/editing .scad files, 3D modeling, parametric designs, or 3D printing models.
user-invocable: false
---

# OpenSCAD Expert Skill

<role>
You are an OpenSCAD expert specializing in parametric 3D modeling.
</role>

<context>
OpenSCAD is a script-based 3D CAD modeler using CSG (Constructive Solid Geometry).
Key concepts: modules, functions, variables, transformations, boolean operations.
</context>

<constraints>
- All measurements in millimeters (mm)
- Use variables for all dimensions
- Follow naming conventions: snake_case for variables, CamelCase for modules
</constraints>

<patterns>
## Rounded Box
```scad
module rounded_box(size, r) {
    hull() {
        for (x = [-1, 1], y = [-1, 1], z = [-1, 1])
            translate([x*(size[0]/2-r), y*(size[1]/2-r), z*(size[2]/2-r)])
                sphere(r);
    }
}
```
</patterns>

<examples>
<example>
<input>Create a 50x30mm bracket with M3 holes</input>
<output>
```scad
// Parametric bracket
bracket_width = 50;
bracket_height = 30;
hole_diameter = 3.2;  // M3 clearance

module bracket() {
    difference() {
        cube([bracket_width, bracket_height, 3]);
        // Mounting holes
        for (x = [10, bracket_width-10])
            translate([x, bracket_height/2, -1])
                cylinder(h=5, d=hole_diameter, $fn=32);
    }
}

bracket();
```
</output>
</example>
</examples>

<instructions>
1. Identify parameters from user request
2. Create parametric modules
3. Use Customizer groups for organization
4. Add comments for non-obvious logic
5. Test with different parameter values
</instructions>
```

## Manual Invocation

If a skill isn't auto-invoked, force it with:
```
/skill skill-name
```

Or for user-invocable skills:
```
/skill-name
```

## Debugging Discovery

If your skill isn't being discovered:

1. **Check description**: Does it include relevant keywords?
2. **Check name**: Is it lowercase with hyphens only?
3. **Check location**: Is it in `~/.claude/skills/` or `.claude/skills/`?
4. **Check structure**: Is SKILL.md in a subdirectory?

Test discovery by asking Claude about a topic your skill covers.

## Sandbox Security (v2.1.38+)

Writes to `.claude/skills` directory are **blocked in sandbox mode**. This prevents skills from self-modifying during sandboxed execution. Skills that need to write files should use a different output directory.

## Best Practices

1. **Keep SKILL.md concise**: < 500 lines, split into reference files
2. **Use XML tags**: Claude handles them well
3. **Include examples**: Concrete input/output pairs
4. **Test triggers**: Ask related questions to verify discovery
5. **Version your skills**: Track changes with version field
6. **Document reference files**: Table showing when to read each
7. **Always add self-update**: Every skill with external resources MUST include a self-update cookbook. See [Self-Update Pattern](#self-update-pattern)
8. **Use `.env` for machine-specific config**: Paths, secrets, user preferences — never hardcode. See [Environment Bootstrap Pattern](#environment-bootstrap-pattern)

### From the agentskills.io Specification

**Start from real expertise**: Extract skills from hands-on task completions, not generic LLM generation. Feed domain-specific artifacts (runbooks, schemas, incident reports, code review history) rather than generic documentation.

**Refine with real execution**: Run the skill against real tasks, read execution traces (not just final outputs), and feed results back. Even one execute-then-revise pass significantly improves quality.

**Add what the agent lacks, omit what it knows**: Skip explaining what PDFs are or how HTTP works. Focus on project-specific conventions, non-obvious edge cases, and concrete tool choices (e.g., "use pdfplumber; for scanned docs, fall back to pdf2image with pytesseract").

**Match specificity to fragility**: Give freedom where multiple approaches are valid; be prescriptive where sequence and consistency matter. Most skills mix both — calibrate each section independently.

**Provide defaults, not menus**: When multiple tools could work, pick one default and briefly mention alternatives as escape hatches. Avoid presenting equal options that force the agent to choose.

**Use gotchas sections**: A list of environment-specific gotchas is often the highest-value content in a skill. These are concrete corrections to mistakes the agent will make without being told (e.g., "The `users` table uses soft deletes — always include `WHERE deleted_at IS NULL`"). Keep gotchas in the main SKILL.md, not a reference file.

**Favor procedures over declarations**: Teach the agent *how to approach* a class of problems, not what to produce for one specific instance. Reusable methods outperform specific answers.

**Plan-validate-execute for batch/destructive ops**: Have the agent create a structured plan, validate it against a source of truth (ideally a script), and only then execute. The key is a validation step that generates actionable error messages for self-correction.

**When to load reference files**: Tell the agent *when* to load each file explicitly (e.g., "Read `references/api-errors.md` if the API returns non-200"). "See references/ for details" is less useful because the agent may not recognize the trigger.

**Design coherent units**: Scope skills like well-named functions — coherent units that compose well. Too narrow forces multiple skills to load; too broad reduces precision. A skill that handles a task and its output formatting is usually one unit; one that also handles administration of the underlying service is probably two.

## Nested Skill Discovery (Monorepos)

Skills in nested `.claude/skills` directories are auto-discovered:
```
project-root/
├── .claude/skills/          # Root-level skills
└── packages/app/
    └── .claude/skills/      # Auto-discovered when working in packages/app
```

## Auto-Loading from Additional Directories (v2.1.32+)

Skills in `.claude/skills/` within directories specified via `--add-dir` are automatically loaded:

```bash
claude --add-dir ./company-skills --add-dir ./team-skills
```

Skills in `./company-skills/.claude/skills/` and `./team-skills/.claude/skills/` are discovered and loaded alongside project and personal skills. Live change detection is supported.

**Note**: CLAUDE.md files from `--add-dir` directories are NOT loaded by default. Set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to enable.

## Plugin Skills

Plugin-provided skills use namespace format:
```
plugin-name:skill-name
```
Example: `my-plugin:formatter`

## Agent Skills Open Standard

Claude Code skills follow the [Agent Skills](https://agentskills.io) open standard. The spec defines additional optional frontmatter fields:

| Field | Description |
|-------|-------------|
| `license` | License name or reference to bundled LICENSE file |
| `compatibility` | Max 500 chars. Environment requirements (product, packages, network) |
| `metadata` | Arbitrary key-value map for custom properties (e.g., `author`, `version`) |

### Open Standard Spec Notes

The [agentskills.io specification](https://agentskills.io/specification) is the canonical format reference. Key points that differ from or extend Claude Code's conventions:

- **`name` is required** in the open spec (must match the parent directory name exactly)
- **`description` is required** (1-1024 chars) in the open spec
- **Directory names**: `references/` (not just `REFERENCE.md`) and `assets/` (templates, images, data files)
- **Portability**: The same SKILL.md works in Claude Code, VS Code Copilot, OpenAI Codex, and other skills-compatible agents
- **Multi-client skill directories**: VS Code looks for skills in `.agents/skills/` by default; Claude Code uses `.claude/skills/`

### Skill Validation (skills-ref)

The [skills-ref](https://github.com/agentskills/agentskills/tree/main/skills-ref) reference library validates SKILL.md files against the open spec:

```bash
# Install
uv sync   # from the skills-ref directory

# Validate a skill
skills-ref validate ./my-skill

# Read parsed properties (JSON)
skills-ref read-properties ./my-skill

# Generate <available_skills> XML for agent prompts
skills-ref to-prompt ./skill-a ./skill-b
```

The `to-prompt` output generates the recommended `<available_skills>` XML block for agent system prompts:
```xml
<available_skills>
  <skill>
    <name>my-skill</name>
    <description>What this skill does and when to use it</description>
    <location>/path/to/my-skill/SKILL.md</location>
  </skill>
</available_skills>
```

## agentskill.sh Marketplace

[agentskill.sh](https://agentskill.sh) is a marketplace with 100,000+ community skills. It provides the `ags` CLI (`npx @agentskill.sh/cli`) for discovering, installing, and managing skills from the registry.

### ags CLI Commands

The CLI runs via npx — no global install needed:

```bash
# Search for skills
npx @agentskill.sh/cli search "<query>" --json --limit 5

# Install a skill by slug
npx @agentskill.sh/cli install @<owner>/<slug> --json

# List installed skills
npx @agentskill.sh/cli list --json

# Update all installed skills
npx @agentskill.sh/cli update --json

# Remove a skill
npx @agentskill.sh/cli remove <slug>

# Rate a skill (1-5)
npx @agentskill.sh/cli feedback <slug> <score> "<comment>"
```

### Search Result Fields

The `search` command returns a `results` array where each skill has:

| Field | Description |
|-------|-------------|
| `slug` | Unique identifier |
| `name` | Display name |
| `owner` | Author handle |
| `description` | What the skill does |
| `installCount` | Download count |
| `securityScore` | Safety rating (0-100) |
| `contentQualityScore` | Content quality rating |

### Install Output Fields

The `install` command returns:

| Field | Description |
|-------|-------------|
| `slug` | Skill identifier |
| `installDir` | Where the skill was written |
| `filesWritten` | Number of files created |
| `securityScore` | Safety score |
| `contentQualityScore` | Quality score |

### Skillsets (Bundles)

Install a bundle of related skills in one command:

```bash
# Fetch skillset info
curl https://agentskill.sh/api/agent/skillsets/<slug>/install

# Then install each skill in the bundle
npx @agentskill.sh/cli install <slug> --json
```

### Trending Skills

```bash
curl "https://agentskill.sh/api/agent/search?section=trending&limit=5"
```

### Security Note

If a skill's `securityScore` is below 30, warn the user before installing. The `learn:scan` skill can perform a deeper security audit of any SKILL.md using a rubric for critical, high, and medium-risk patterns.

### The `learn` Skill (Skill Manager)

The `learn:learn` skill (from the `agentskill-sh` plugin) is the recommended way to interact with the marketplace conversationally. Use it with:

```
/learn <query>           # Search and install interactively
/learn @owner/slug       # Install exact skill
/learn skillset:<slug>   # Install a bundle
/learn trending          # Show trending skills
/learn list              # Show installed skills
/learn update            # Check for updates
/learn remove <slug>     # Uninstall a skill
/learn feedback <slug> <1-5> [comment]  # Rate a skill
/learn scan [path]       # Security scan a SKILL.md
```

## Visual Output Pattern

Skills can bundle scripts that generate interactive HTML:

```yaml
---
name: codebase-visualizer
description: Generate interactive tree visualization of the codebase
allowed-tools: Bash(python *)
---

Run the visualization script:
```bash
python ${CLAUDE_SKILL_DIR}/scripts/visualize.py .
```
```

The script generates a self-contained HTML file and opens it in the browser. Works for dependency graphs, test coverage reports, API docs, schema visualizations, etc.

## Plugin System

Skills can be distributed via plugins. Plugins bundle skills, agents, hooks, MCP servers, and LSP servers:

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json          # Required: {"name": "my-plugin", "version": "1.0.0"}
├── skills/                  # Skills (SKILL.md in subdirs)
├── agents/                  # Agent definitions
├── hooks/hooks.json         # Hook configurations
├── .mcp.json                # MCP server configs
├── .lsp.json                # LSP server configs (code intelligence)
├── settings.json            # Default settings (currently only `agent` key)
└── README.md
```

### Key Plugin Concepts

- Plugin skills are namespaced: `/plugin-name:skill-name`
- Install: `/plugin install plugin-name@marketplace` or `claude plugin install`
  - **Note**: Organization policy may block plugin installation. If blocked, contact your admin.
- Test locally: `claude --plugin-dir ./my-plugin`
- `${CLAUDE_PLUGIN_ROOT}` env var for portable paths in hooks/scripts
- `${CLAUDE_PLUGIN_DATA}` env var for persistent plugin state (survives updates) (v2.1.78+)
- Plugin cache at `~/.claude/plugins/cache`
- Reload after changes: `/reload-plugins`
- **Plugin executables** (v2.1.91+): Plugins can ship executables under `bin/` that are invoked as bare commands (e.g., `my-plugin` runs `<plugin-root>/bin/my-plugin`)

### LSP Servers in Plugins (Code Intelligence)

Claude Code has a **built-in LSP tool** (since v2.0.74, Dec 2025). Plugins from the official marketplace (`claude-plugins-official`, auto-added) wire a language server binary into that tool. No feature flag needed — the old `ENABLE_LSP_TOOL=1` env var from early blog posts is obsolete.

**Two capabilities Claude gains once an LSP plugin is installed:**

1. **Automatic diagnostics** — after every file edit, the language server reports type errors, missing imports, and syntax issues back to Claude. Claude sees errors and fixes them in the same turn. Press `Ctrl+O` to view inline when the "diagnostics found" indicator appears.
2. **Code navigation** — Claude can jump to definitions, find references, get hover types, list symbols, find implementations, and trace call hierarchies. More precise than grep.

**Official pre-built LSP plugins** (from `claude-plugins-official`):

| Language   | Plugin              | Binary required              |
| :--------- | :------------------ | :--------------------------- |
| C/C++      | `clangd-lsp`        | `clangd`                     |
| C#         | `csharp-lsp`        | `csharp-ls`                  |
| Go         | `gopls-lsp`         | `gopls`                      |
| Java       | `jdtls-lsp`         | `jdtls`                      |
| Kotlin     | `kotlin-lsp`        | `kotlin-language-server`     |
| Lua        | `lua-lsp`           | `lua-language-server`        |
| PHP        | `php-lsp`           | `intelephense`               |
| Python     | `pyright-lsp`       | `pyright-langserver`         |
| Rust       | `rust-analyzer-lsp` | `rust-analyzer`              |
| Swift      | `swift-lsp`         | `sourcekit-lsp`              |
| TypeScript | `typescript-lsp`    | `typescript-language-server` |

**Setup workflow** (two steps per language):

```bash
# 1. Install the language server binary (examples)
uv tool install pyright                              # Python
bun add -g typescript-language-server typescript     # TypeScript
rustup component add rust-analyzer                   # Rust

# 2. Install the plugin at user scope
claude plugin install pyright-lsp@claude-plugins-official --scope user
claude plugin install typescript-lsp@claude-plugins-official --scope user
claude plugin install rust-analyzer-lsp@claude-plugins-official --scope user

# 3. Reload (no restart needed)
/reload-plugins
```

Verify in `/plugin` → **Installed** tab. If **Errors** tab shows `Executable not found in $PATH`, the binary is missing or not on PATH.

**Custom LSP plugins** — for unsupported languages, create your own plugin with a `.lsp.json`:

```json
// .lsp.json
{
  "go": {
    "command": "gopls",
    "args": ["serve"],
    "extensionToLanguage": { ".go": "go" }
  }
}
```

**Caveats:**
- `rust-analyzer` and `pyright` can consume significant RAM on large monorepos — disable per-project if needed (`/plugin disable <name>`)
- Monorepos may show false-positive unresolved-import warnings; doesn't block edits
- Pyright auto-detects `.venv/` for `uv` projects; for custom layouts, set `venvPath`/`venv` in `pyproject.toml [tool.pyright]`
- A plugin can be installed but **disabled** — verify status in `/plugin` Installed tab
- If LSP server crashes, it now auto-restarts on next request (fixed April 2026)

## Environment Variables

- `SLASH_COMMAND_TOOL_CHAR_BUDGET` - Character budget for skill descriptions (scales to 2% of context window; fallback minimum 16,000 chars)
- `CLAUDE_CODE_DISABLE_CRON` - Immediately stop scheduled cron jobs mid-session (v2.1.72)
- `CLAUDE_CODE_PLUGIN_SEED_DIR` - Seed directory for plugins. Supports multiple directories (v2.1.79+)
- `disableSkillShellExecution` - Managed setting (v2.1.91+). Set to `true` to disable inline shell execution in skills and custom commands

## Advanced Patterns

### Cookbook/Prompts Pattern
Separate workflow logic from the main skill file:

```
skill-name/
├── SKILL.md              # Decision tree + quick reference
├── cookbook/             # Complex workflows with full context
│   └── install.md        # Complete installation workflow
└── prompts/              # Reusable prompt templates
    └── build.md          # Build workflow template
```

**In SKILL.md:**
```markdown
## Cookbook

### Installation
**Trigger**: "install", "setup"
**Workflow**: Read and execute [cookbook/install.md](cookbook/install.md)
```

**In cookbook/install.md:**
```yaml
---
model: opus
description: Interactive workflow to install the skill
---

# Purpose
Guide the user through installation.

## Variables
TARGET_DIR: ~/.claude/skills/

## Instructions
- Use AskUserQuestion at each decision point
- Verify installation by checking file existence

## Workflow
### Step 1: Choose Location
1. Use AskUserQuestion to determine install location

### Step 2: Copy Files
...

## Report
Present the installation summary.
```

### Progressive Disclosure Pattern
Use numbered examples to control context loading:

```
skill-name/
├── SKILL.md
└── examples/
    ├── 01_basic.md        # Read first for simple tasks
    ├── 02_intermediate.md # Read when needed
    └── 03_advanced.md     # Read for complex scenarios
```

**In SKILL.md:**
```markdown
## Examples

**Progressive Disclosure**: Read only the example you need.

### Example 1: Basic Usage
**Read when**: Simple task, getting started
**See**: [examples/01_basic.md](examples/01_basic.md)

### Example 2: Advanced Usage
**Read when**: Complex task, multiple steps
**See**: [examples/02_advanced.md](examples/02_advanced.md)
```

### Variables + Instructions Pattern
Use clear variable definitions for reusability:

```markdown
## Variables

SKILL_DIR: .claude/skills/my-skill
CONFIG_FILE: SKILL_DIR/config.yaml
TIMEOUT_SECONDS: 43200
DEFAULT_PORT: 5173

## Instructions

- **ALWAYS USE --timeout TIMEOUT_SECONDS**
- Change directory to SKILL_DIR before operations
- Use DEFAULT_PORT unless specified otherwise
- Never create files outside SKILL_DIR
```

### Environment Bootstrap Pattern

Make skills portable by loading machine-specific configuration from a `.env` file on first run.

**When to use**: The skill needs paths, secrets, or preferences that vary per machine. Never hardcode these values.

#### Directory Structure
```
skill-name/
├── SKILL.md
├── .env              # Machine-specific config (gitignored)
├── cookbook/
└── ...
```

#### `.env` Format
```bash
# One KEY=VALUE per line
OUTPUT_PATH=~/Documents/obsidian-vault
API_ENDPOINT=https://api.example.com
PREFERRED_FORMAT=markdown
```

#### Bootstrap Section Template

Add this section to SKILL.md **before** Argument Routing or Workflow:

```markdown
## Variables

- **SKILL_DIR**: directory containing this SKILL.md
- **ENV_FILE**: SKILL_DIR/.env
- **OUTPUT_PATH**: loaded from ENV_FILE (see Bootstrap below)

## Bootstrap: Load Configuration

Before anything else (including Argument Routing), resolve configuration:

1. **Read** `ENV_FILE` (i.e., `SKILL_DIR/.env`)
2. **If the file exists** and contains a non-empty `OUTPUT_PATH=` value:
   - Set the variable to that value (strip quotes if present)
3. **If the file does not exist or the key is empty/missing**:
   - Ask the user via `AskUserQuestion`:
     > "Where should output files be stored? Enter the full path:"
   - Write the answer to `ENV_FILE` as: `OUTPUT_PATH=<user's answer>`
   - Set the variable to the user's answer
```

#### Use Cases

| Type | How to Resolve | Example |
|------|---------------|---------|
| Paths | `AskUserQuestion` with example path | `OUTPUT_PATH=~/Documents/notes` |
| Secrets | `bw-fetch password "<name>"` piped into `.env` | `API_KEY=sk-...` |
| Preferences | `AskUserQuestion` with options | `FORMAT=markdown` |

#### Agent Companion

If the skill has an associated agent in `~/.claude/agents/`, the agent should reference the **same** `.env` file via absolute path:

```markdown
## Variables

- **SKILL_DIR**: ~/.claude/skills/skill-name
- **ENV_FILE**: SKILL_DIR/.env
```

This way configuring once (from either the skill or the agent) works for both.

#### `.gitignore`

Always exclude `.env` from version control. If the skill is tracked in a dotfiles repo, add:
```
dotfiles/dot-claude/skills/skill-name/.env
```

### Argument Hint Pattern
For prompts that accept arguments:

```yaml
---
description: Build the application from a plan
argument-hint: [path-to-plan] [options]
---

# Build

## Variables
PATH_TO_PLAN: $1
OPTIONS: $2 default "" if not provided
```

### Self-Update Pattern

**MANDATORY**: Every skill that references external resources (documentation URLs, APIs, libraries, specifications) MUST include a self-update cookbook workflow. This ensures skills stay current as upstream sources evolve.

#### Required Components

1. **External Resources Table** in SKILL.md:
```markdown
## External Resources

| Source | URL | Maps To |
|--------|-----|---------|
| Official Docs | https://example.com/docs | REFERENCE.md |
| GitHub Releases | https://github.com/org/repo/releases | All files |
| API Reference | https://example.com/api | API.md |
```

2. **Argument routing** in SKILL.md:
```markdown
## Argument Routing

**If $ARGUMENTS is "self-update"**: Read and execute [cookbook/self-update.md](cookbook/self-update.md)
```

3. **`argument-hint`** in frontmatter:
```yaml
---
argument-hint: [self-update]
---
```

4. **`cookbook/self-update.md`** workflow file following this template:

```markdown
# Self-Update Workflow

Fetch latest documentation and resources, review all reference files, and auto-apply updates.

## Variables

SKILL_DIR = <path-to-skill>
STATE_FILE = $SKILL_DIR/.self-update-state.json

### Documentation URLs

| Source | URL | Maps To |
|--------|-----|---------|
| <copy from SKILL.md External Resources table> |

## Workflow

### Step 0: Read State File
Read `$STATE_FILE` to get last update timestamp.
- If missing or corrupt, treat as first run

### Step 1: Fetch Documentation (Parallel)
Launch parallel WebFetch calls for each URL in the resources table.
Each call extracts structured information relevant to the mapped file.

### Step 2: Launch Parallel Review Agents
Launch one Task agent (subagent_type: general-purpose, model: haiku) per reference file.

Each agent receives:
- Fetched documentation as context
- One assigned reference file to review
- Instructions to return: outdated_sections[], new_content[], corrections[]

### Step 3: Collect and Apply Updates
- Consolidate findings, deduplicate
- Apply corrections first, then content updates, then new sections
- Verify files parse correctly after edits

### Step 4: Update State File
Write updated state with timestamp, version, files updated, changes applied.

### Step 5: Generate Report
Output summary table: files reviewed, files updated, changes applied.
```

#### Example: cloud-expert skill with self-update
```
cloud-expert/
├── SKILL.md                    # Has External Resources table + argument routing
├── RCLONE.md
├── GOOGLE-DRIVE.md
├── ONEDRIVE.md
├── cookbook/
│   └── self-update.md          # Fetches rclone docs, cloud provider docs
└── .self-update-state.json     # Auto-generated state tracking
```

**In SKILL.md:**
```markdown
## External Resources

| Source | URL | Maps To |
|--------|-----|---------|
| Rclone Docs | https://rclone.org/docs/ | RCLONE.md |
| Rclone Releases | https://github.com/rclone/rclone/releases | All files |
| OneDrive Config | https://rclone.org/onedrive/ | ONEDRIVE.md |
| Google Drive Config | https://rclone.org/drive/ | GOOGLE-DRIVE.md |

## Argument Routing

**If $ARGUMENTS is "self-update"**: Read and execute [cookbook/self-update.md](cookbook/self-update.md)
```

The user invokes self-update with: `/cloud-expert self-update`

### Config as Single Source of Truth
Use YAML/JSON for shared configuration:

```yaml
# patterns.yaml - Single source of truth
blockedCommands:
  - pattern: '\brm\s+-rf'
    reason: Dangerous recursive delete

protectedPaths:
  - ".env"
  - "~/.ssh/"
```

Reference in multiple scripts:
```python
# hook.py
import yaml
config = yaml.safe_load(open("patterns.yaml"))
```

### Tools Integration
Include helper tools with your skill:

```
skill-name/
├── SKILL.md
└── tools/
    └── helper.py   # Executable helper script
```

**In SKILL.md:**
```markdown
## Workflow

1. Execute the helper tool:
\`\`\`bash
uv run .claude/skills/skill-name/tools/helper.py "argument"
\`\`\`
```

## Commands Integration

Skills can work with commands (`.claude/commands/`) for quick invocation:

### Prime Command Pattern
A `/prime` command orients the agent on a codebase:

```yaml
---
description: Prime agent on the codebase
allowed-tools: Bash, Read, Glob
---

# Purpose
Get oriented on the codebase. Read-only exploration.

## Workflow
- `git ls-files`
- Read `README.md`
- Read `.claude/skills/skill-name/SKILL.md`

## Report
Summarize what you learned.
```

### Workflow Command Pattern
Chain multiple skill prompts in sequence:

```yaml
---
description: Full workflow - plan, build, test, deploy
argument-hint: [user_prompt]
---

# Purpose
Complete end-to-end workflow.

## Variables
USER_PROMPT: $1

## Workflow
> Run top to bottom. DO NOT STOP between steps.

1. **Plan**: Run `\skill-name:plan [USER_PROMPT]`
2. **Build**: Run `\skill-name:build [path_to_plan]`
3. **Test**: Run `\skill-name:test`
4. **Report**: Summarize all steps
```
