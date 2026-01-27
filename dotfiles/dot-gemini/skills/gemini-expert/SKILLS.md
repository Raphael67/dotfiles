# Agent Skills

Skills extend the Gemini CLI with specialized expertise, procedural workflows, and task-specific resources. They are "on-demand" expert personas.

## Locations
1.  **Workspace Skills:** `<project-root>/.gemini/skills/`
2.  **User Skills:** `~/.gemini/skills/`

## Structure
A skill is a directory containing a `SKILL.md` file.

```text
my-skill/
├── SKILL.md          # Definition and instructions
├── scripts/          # Optional helper scripts
└── templates/        # Optional text templates
```

## SKILL.md Format
The file consists of YAML frontmatter and a Markdown body.

```markdown
---
name: my-skill
description: Detailed description of what this skill does and when to use it.
user-invocable: true  # Can be triggered via /activate_skill
---

# My Skill Instructions

## Purpose
...

## Steps
1. ...
2. ...

<AVAILABLE_RESOURCES>
  <resource>
    <path>scripts/helper.py</path>
    <description>Helper script</description>
  </resource>
</AVAILABLE_RESOURCES>
```

### Frontmatter Fields
*   `name`: Unique ID (kebab-case).
*   `description`: **Critical.** Used by the model to decide if it should activate the skill autonomously. Be specific.
*   `user-invocable`: (Boolean) Allows users to manually activate it.

## Activation
*   **Manual:** User runs `/activate_skill name="my-skill"`.
*   **Auto:** Gemini decides to call `activate_skill` based on the user's request and the skill's `description`.

## Sub-Agents & Registry
Gemini now supports a more robust `AgentRegistry` for managing specialized sub-agents.
*   **Capabilities:** Sub-agents can now accept strict JSON schema inputs, improving reliability for complex tasks.
*   **Discovery:** Use the `/agents config` command to manage and discover available agents.

## Standard Skills
New installations often include standard skills:
*   **docs-writer:** specialized in generating and maintaining project documentation.

## Best Practices
*   **Specialized:** Keep skills focused (e.g., `react-migration`, `sql-optimization`).
*   **Procedural:** Use the instructions to enforce a specific workflow (e.g., "Always run tests before committing").
*   **Resources:** Use `<AVAILABLE_RESOURCES>` to expose specific files to the agent context upon activation.
