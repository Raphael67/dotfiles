---
paths:
  - "dot-claude/hooks/notify/**"
---

# claude-notify.sh — non-obvious constraints

`dotfiles/dot-claude/hooks/notify/claude-notify.sh` is the single notification
emitter for Claude Code, wired to `Notification` and `SubagentStop`. It replaced
ccnotify and a test hook.

- **Ghostty via tmux client tty, not tmux itself**: tmux discards OSC 777, so the
  hook writes the escape sequence straight to `tmux list-clients -F
  '#{client_tty}'`, bypassing tmux's parser. Ghostty then posts the notification
  (attributed to `com.mitchellh.ghostty`), which can be allow-listed in a Focus
  mode and comes to the front when clicked.
- **`SubagentStop` reads stdout JSON as a request to block the subagent** — this
  hook must print nothing on stdout and always `exit 0`.
- **`agent_type` arrives as `""`, not `null`, for nested/unnamed subagents.** jq's
  `//` only falls through on `null`, never on `""` — use an explicit
  `map(select(. != null and . != ""))` instead of a `//` chain.
- **`;` is the OSC 777 field separator** and must be stripped from title/body.
- **Only named agents get a banner.** Measured 2026-08-23: 51 of 62 `SubagentStop`
  events had empty `agent_type` (nested/internal agents Claude Code never names).
  Notifying on those recreates the exact spam the event filter was meant to avoid
  — exit early when `agent_type` is empty; an empty type is itself the signal
  that no banner is wanted.
- **`lsappinfo front`** gives the frontmost bundle id with no Accessibility
  permission (unlike System Events) — used to skip the banner when the user is
  already looking at the pane.
- Raw payloads are logged to `$TMPDIR/claude-notify.log`, capped at 256 KB.
