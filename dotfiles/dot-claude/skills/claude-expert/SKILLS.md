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
| `argument-hint` | No | Hint shown during autocomplete (e.g., `[issue-number]`) |

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

### Session Variables
- `${CLAUDE_SESSION_ID}` - Current session ID for logging/tracking

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

## Best Practices

1. **Keep SKILL.md concise**: < 500 lines, split into reference files
2. **Use XML tags**: Claude handles them well
3. **Include examples**: Concrete input/output pairs
4. **Test triggers**: Ask related questions to verify discovery
5. **Version your skills**: Track changes with version field
6. **Document reference files**: Table showing when to read each
7. **Always add self-update**: Every skill with external resources MUST include a self-update cookbook. See [Self-Update Pattern](#self-update-pattern)

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

Skills in `./company-skills/.claude/skills/` and `./team-skills/.claude/skills/` are discovered and loaded alongside project and personal skills.

## Plugin Skills

Plugin-provided skills use namespace format:
```
plugin-name:skill-name
```
Example: `my-plugin:formatter`

## Environment Variables

- `SLASH_COMMAND_TOOL_CHAR_BUDGET` - Character budget for skill descriptions (default: 15,000 characters; scales to 2% of context window in v2.1.32+)

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
