---
paths:
  - "**/dot-claude/rules/communication.md"
  - "**/dot-claude/agents/claude-style.md"
  - "**/dot-claude/commands/claude-style.md"
---

# claude-style — the communication contract mechanism

Three pieces, one owner.

| File | Role |
|------|------|
| `dotfiles/dot-claude/rules/communication.md` | The contract. Loaded in every session. |
| `dotfiles/dot-claude/agents/claude-style.md` | The curator. **Sole writer** of the contract. |
| `dotfiles/dot-claude/commands/claude-style.md` | `/claude-style <remark>` — the synchronous entry point. |

## Invariants

- **The contract carries no `paths:` frontmatter.** A user-level rule without `paths:`
  loads unconditionally; adding `paths:` would make it load only when a matching file is
  read, silently disabling the whole mechanism. This is the single failure mode that
  looks like nothing is wrong.
- **Budget: 40 content lines** in the contract (`grep -vcE '^\s*$|^#|^<!--'`). Over
  budget, the agent merges or evicts before adding.
- **Strengthening beats adding.** A remark already covered by a rule sharpens that rule
  in place; it never produces a near-duplicate line.
- **Public repo.** The contract is committed publicly. No verbatim excerpt from a
  professional session ever lands in it — counter-examples are reworded neutrally.
- **Atemporal**, like every rule here: no dates, no hashes, no "recently fixed".
- Nothing else writes to the contract. The global `CLAUDE.md` deliberately has no
  `## Communication` section any more — do not reintroduce one.

## Two triggers, one writer

`/claude-style <remark>` dispatches the agent synchronously; the agent reads the raw
session transcript rather than trusting the main loop's account of its own slip.

The `self-healing` skill is the batch path: its classifier has a `COMMUNICATION_STYLE`
category, and phase 3 delegates that group to the same agent instead of writing to
`self-healing.md`. Keep it that way — a style rule living in two stores is how
contradictory duplicates appear.

Scope boundary: style and conversational behaviour only. Workflow, tooling, git and
technical errors stay with `self-healing`, the `commit` agent, or the global CLAUDE.md.
