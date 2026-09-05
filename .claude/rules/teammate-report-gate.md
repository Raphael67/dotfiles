---
paths:
  - "dot-claude/hooks/teammate-report-gate.py"
---

# teammate-report-gate.py — why this hook exists

Router/executor/planner/quick agents run as **named teammates**, not plain
subagents. A teammate's final text is NOT auto-returned to the lead — the only
channel back is an explicit `SendMessage` call. Workers routinely end a work
cycle with a prose summary and go idle without calling `SendMessage`, so the
lead receives only a content-free `idle_notification` and the result is lost.

`teammateMode: tmux` masked this bug because each teammate had a visible pane
the user could read directly; switching to `in-process` (no panes) exposed it.

**Fix**: a `TeammateIdle` hook gate. On idle, if the teammate did work this
cycle but never called `SendMessage`, it exits 2 to block idle and feed back
"report first." Fails **open** on any error (never traps a teammate); bounded
to 2 nudges then gives up. Debug log:
`~/.claude/state/teammate-report-gate/debug.log`.

**Caveat**: hooks snapshot at startup — restart Claude Code (or re-review via
`/hooks`) for changes to this file to take effect.
