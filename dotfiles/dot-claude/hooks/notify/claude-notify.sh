#!/usr/bin/env bash
# Native macOS notifications for Claude Code, delivered through Ghostty.
#
# WHY THIS SHAPE:
#   Ghostty renders OSC 777 as a real macOS notification attributed to
#   com.mitchellh.ghostty — a signed bundle that can be added to a Focus mode's
#   allow-list and that comes to the front when the banner is clicked. Neither
#   osascript (attributed to com.apple.scripteditor2) nor terminal-notifier
#   offers a stable, allow-listable identity here.
#
#   The escape sequence must reach Ghostty, not tmux: tmux discards OSC 777, so
#   we write straight to the attached client's tty and bypass tmux's parser.
#   Claude Code's own `preferredNotifChannel: "ghostty"` emits no OSC sequence
#   (verified against 2.1.228), which is why this hook exists.
#
# WIRED TO: Notification and SubagentStop in ~/.claude/settings.json.
#   Receives the hook payload on stdin. Always exits 0 and never writes to
#   stdout — SubagentStop reads stdout JSON as a request to block the subagent.

set -uo pipefail

EVENT="${1:-Unknown}"
PAYLOAD="$(cat)"

LOG="${TMPDIR:-/tmp}/claude-notify.log"
LOG_MAX=262144

log() { printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG" 2>/dev/null; }

if [[ -f "$LOG" ]] && (( $(wc -c <"$LOG" 2>/dev/null || echo 0) > LOG_MAX )); then
    tail -n 200 "$LOG" >"$LOG.tmp" 2>/dev/null && mv "$LOG.tmp" "$LOG" 2>/dev/null
fi
log "EVENT=$EVENT PAYLOAD=$PAYLOAD"

field() { printf '%s' "$PAYLOAD" | jq -r "$1 // empty" 2>/dev/null; }

CWD=$(field '.cwd')
MESSAGE=$(field '.message')
NTYPE=$(field '.notification_type')
# The SubagentStop matcher is the agent type, but the payload field carrying it
# is undocumented — try the plausible names rather than guessing one.
AGENT=$(field '.agent_type // .subagent_type // .agent_name')

# Strip anything that would break the OSC sequence: ';' is its field separator,
# BEL terminates it, and control characters corrupt it. Bash substring keeps the
# truncation character-aligned so UTF-8 is never cut mid-codepoint.
sanitize() {
    local s="${1//$'\n'/ }"
    s="${s//$'\r'/ }"
    s="${s//$'\t'/ }"
    s="${s//;/,}"
    s=$(printf '%s' "$s" | tr -d '\000-\037\177')
    printf '%s' "${s:0:180}"
}

# --- locate the tmux window this session lives in -------------------------
TARGET_SESSION=""
TARGET_LABEL=""
PANE_TTY=""
WINDOW_ACTIVE=""
if [[ -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
    read -r TARGET_SESSION TARGET_LABEL PANE_TTY WINDOW_ACTIVE < <(
        tmux display-message -p -t "$TMUX_PANE" \
            '#{session_name} #{session_name}:#{window_index} #{pane_tty} #{window_active}' 2>/dev/null
    )
fi
[[ -n "$TARGET_LABEL" ]] || TARGET_LABEL=$(basename "${CWD:-Claude}")

# Name the project too when it is not already obvious from the session name.
PROJECT=$(basename "${CWD:-}")
LABEL="$TARGET_LABEL"
[[ -n "$PROJECT" && "$TARGET_SESSION" != "$PROJECT" ]] && LABEL="$TARGET_LABEL ($PROJECT)"

case "$EVENT" in
    Notification)  TITLE="🔔 $LABEL"; BODY="${MESSAGE:-${NTYPE:-Claude needs you}}" ;;
    SubagentStop)  TITLE="✅ $LABEL"; BODY="agent ${AGENT:-agent} terminé" ;;
    *)             TITLE="$LABEL";    BODY="$EVENT" ;;
esac
TITLE=$(sanitize "$TITLE")
BODY=$(sanitize "$BODY")

# --- tmux bell: a persistent signal that survives detaching ---------------
[[ -n "$PANE_TTY" ]] && printf '\a' >"$PANE_TTY" 2>/dev/null

# --- skip the banner when you are already looking at that window ----------
FRONT=$(lsappinfo info -only bundleid "$(lsappinfo front 2>/dev/null)" 2>/dev/null |
        sed -n 's/.*bundleID="\([^"]*\)".*/\1/p')
if [[ "$FRONT" == "com.mitchellh.ghostty" && "$WINDOW_ACTIVE" == "1" && -n "$TARGET_SESSION" ]] &&
   tmux list-clients -F '#{client_session}' 2>/dev/null | grep -Fxq "$TARGET_SESSION"; then
    log "SUPPRESSED (Ghostty frontmost on $TARGET_LABEL): $TITLE / $BODY"
    exit 0
fi

# --- deliver --------------------------------------------------------------
TTYS=""
if [[ -n "$TARGET_SESSION" ]]; then
    TTYS=$(tmux list-clients -t "$TARGET_SESSION" -F '#{client_tty}' 2>/dev/null)
fi
if [[ -z "$TTYS" ]] && command -v tmux >/dev/null 2>&1; then
    TTYS=$(tmux list-clients -F '#{client_tty}' 2>/dev/null)
    [[ -n "$TTYS" ]] && log "no client on '$TARGET_SESSION', falling back to every attached client"
fi
# Outside tmux entirely, the controlling terminal is Ghostty itself.
[[ -z "$TTYS" && -e /dev/tty ]] && TTYS=/dev/tty

if [[ -z "$TTYS" ]]; then
    log "UNDELIVERED (no attached client): $TITLE / $BODY"
    exit 0
fi

while IFS= read -r tty; do
    [[ -w "$tty" ]] || continue
    printf '\033]777;notify;%s;%s\007' "$TITLE" "$BODY" >"$tty" 2>/dev/null
    log "SENT -> $tty : $TITLE / $BODY"
done <<<"$TTYS"

exit 0
