---
description: Feed a remark about Claude's phrasing or response habits to the claude-style curator
argument-hint: <remark> | --bootstrap
---

# /claude-style

Route a remark about **how** Claude answered — phrasing, tone, length, structure,
repetition, out-of-scope content, unrequested action, when to ask versus act — to the
`claude-style` agent, which owns the global communication contract.

## Variables

REMARK: $ARGUMENTS

## Instructions

- You are the culprit being reported. **Never paraphrase, soften, or interpret the
  remark** — pass it through verbatim, and let the agent read the transcript itself.
- Do not edit `rules/communication.md` yourself. The agent is its sole writer.
- Do not answer the remark, do not apologise, do not explain yourself. Dispatch, relay,
  stop. The conversation in progress continues afterwards, unaffected.

## Workflow

### Step 1 — Locate the current transcript

```bash
ls -t "$HOME/.claude/projects/$(pwd | sed 's#/#-#g')"/*.jsonl 2>/dev/null | head -5
```

The current session is normally the most recent one, but concurrent sessions share the
directory. **Verify** by checking that the candidate file contains the remark verbatim
in its last lines (`tail -50 <file> | grep -F '<a distinctive fragment of REMARK>'`).
If it does not match, test the next candidates in order.

### Step 2 — Dispatch

Launch the `claude-style` agent (`Agent` tool, `subagent_type: "claude-style"`,
`name: "claude-style"`) with:

- REMARK, verbatim and unaltered;
- the absolute path of the transcript file resolved in step 1;
- an anchor: the line number of the last `assistant` entry preceding the remark, plus a
  one-line factual note of what the user had asked for at that point — no self-defence.

If REMARK is `--bootstrap`, dispatch the agent in bootstrap mode instead: no transcript,
no anchor.

### Step 3 — Relay

Relay the agent's report as it stands — the diff, the budget, the pending dotfiles
changes. Add nothing. Then terminate the agent (`shutdown_request`).
