# Claude Code Skills Reference

## What Are Skills?

Skills are markdown files that extend Claude Code's capabilities by providing specialized instructions, context, and patterns for specific domains or tasks.

## How Skills Work

1. **Startup**: Claude Code loads the **name** and **description** of each installed skill
2. **Discovery**: Claude automatically decides when to use a skill based on these metadata
3. **Loading**: Full skill content is loaded only when invoked
4. **Execution**: Claude follows the skill's instructions for the task

**Critical**: The description determines if Claude will find and use your skill.

## Directory Structure

```
.claude/skills/
└── skill-name/              # Directory (lowercase, hyphens)
    ├── SKILL.md             # Main file (REQUIRED)
    ├── REFERENCE.md         # Additional docs (optional)
    ├── PATTERNS.md          # Code patterns (optional)
    └── scripts/             # Helper scripts (optional)
        └── helper.py
```

### Locations
- **Personal**: `~/.claude/skills/skill-name/SKILL.md`
- **Project**: `.claude/skills/skill-name/SKILL.md` (shared via git)

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
| `name` | Yes | Unique name, **lowercase + hyphens only**, max 64 chars |
| `description` | Yes | What + when, max 1024 chars. **Critical for discovery** |
| `user-invocable` | No | `true` to allow `/skill-name` invocation |
| `allowed-tools` | No | Restrict available tools (e.g., `Read, Grep, Glob`) |
| `version` | No | Version number for tracking |
| `disable-model-invocation` | No | `true` to disable auto-invocation |

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
