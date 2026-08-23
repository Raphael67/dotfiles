# User-level OpenSpec schemas

Stowed to `~/.local/share/openspec/schemas/` — OpenSpec's user override directory.

## Why this exists

OpenSpec resolves a schema in this order (`src/core/artifact-graph/resolver.ts`):

1. project — `<repo>/openspec/schemas/<name>/`
2. **user — this directory**
3. package — the npm install's built-in `schemas/`

`spec-driven` here therefore **shadows the built-in one in every project**, with no
per-project `openspec/config.yaml`. Templates and instructions are re-read from disk on
every `openspec instructions ... --json` call, so edits take effect immediately —
no `openspec init`, no `openspec update`.

## What is customised

`spec-driven` is a fork of the built-in schema with mermaid diagrams made mandatory:

- `templates/proposal.md` — added `## At a Glance` (one situating diagram)
- `templates/design.md` — added `## Architecture` and `## Flow`
- `schema.yaml` — `proposal` and `design` instructions declare those sections and
  require at least one mermaid block in every design.md

`spec.md` and `tasks.md` are **deliberately untouched**: delta specs go through a
semantic merge at archive time that only carries over `## Purpose` and
`### Requirement:` blocks, so a free-standing diagram section in a spec is silently
dropped. Diagrams belong in proposal/design, which are archived verbatim.

## Rebasing on a new OpenSpec release

Forked from **@fission-ai/openspec 1.10.0** on 2026-08-23.

The built-in schema changes rarely (14 commits in the project's history, all
`instruction:` wording), and validation rules live in OpenSpec's code, not here — so a
stale fork degrades gently. Still, after upgrading the CLI:

```bash
diff -ru "$(npm root -g)/@fission-ai/openspec/schemas/spec-driven" \
         ~/.local/share/openspec/schemas/spec-driven
```

Everything reported beyond the customisations listed above is upstream drift worth
folding in. Then update the version stamp above.

## Verifying it is active

```bash
openspec schema which spec-driven   # must print  Source: user
openspec schema validate spec-driven
```
