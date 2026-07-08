# /// script
# requires-python = ">=3.8"
# dependencies = []
# ///
"""
TeammateIdle report-back gate
=============================

Problem this solves
-------------------
Named teammates (agent teams) do NOT auto-return their final text to the lead.
The ONLY channel back is an explicit `SendMessage` tool call. Models routinely
end a work cycle with a prose summary and go idle WITHOUT calling SendMessage,
so the lead receives only a content-free `idle_notification` and the result is
lost. (In tmux mode this was masked because each teammate had a visible pane.)

What this hook does
-------------------
Fires on `TeammateIdle` (in the teammate's own context, with the teammate's
transcript_path). If the teammate is about to go idle WITHOUT having called
SendMessage since the last inbound message from the lead/user this work cycle,
it blocks the idle (exit 2) and feeds back an instruction to report first.

Safety
------
- FAILS OPEN: any error, missing/unreadable transcript, or missing fields ->
  exit 0 (allow idle). A gate that wrongly blocks would trap a teammate in an
  infinite work loop, which is worse than the original bug.
- BOUNDED: at most MAX_NUDGES consecutive blocks per (session, agent) idle
  cycle, then it gives up and allows idle. Prevents loops when a teammate
  genuinely cannot/should not send (e.g. an ack-only cycle).
"""
import json
import os
import sys
from typing import NoReturn

MAX_NUDGES = 2
STATE_DIR = os.path.expanduser("~/.claude/state/teammate-report-gate")
DEBUG_LOG = os.path.join(STATE_DIR, "debug.log")


def allow(reason="") -> NoReturn:
    """Permit the teammate to go idle."""
    if reason:
        log({"decision": "allow", "reason": reason})
    sys.exit(0)


def block(message) -> NoReturn:
    """Block idle; stderr is fed back to the teammate to keep it working."""
    log({"decision": "block"})
    print(message, file=sys.stderr)
    sys.exit(2)


def log(record):
    """Best-effort one-line debug log. Never raises."""
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(DEBUG_LOG, "a") as f:
            f.write(json.dumps(record) + "\n")
    except Exception:
        pass


def read_transcript(path):
    rows = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                rows.append(json.loads(line))
            except Exception:
                continue
    return rows


def sent_message_since_last_inbound(rows):
    """
    Walk the transcript backwards. The current work cycle starts after the most
    recent inbound message (the lead's dispatch or a lead ping appears as a
    `type:"user"` row in the teammate transcript). Return True if any assistant
    turn in this cycle contains a SendMessage tool_use, and whether the teammate
    produced any substantive assistant turn at all.
    """
    has_send = False
    did_work = False
    for row in reversed(rows):
        rtype = row.get("type")
        if rtype == "user":
            # Reached the start of the current cycle.
            break
        if rtype != "assistant":
            continue
        content = row.get("message", {}).get("content", [])
        if not isinstance(content, list):
            continue
        for block_ in content:
            if not isinstance(block_, dict):
                continue
            btype = block_.get("type")
            if btype == "tool_use":
                did_work = True
                if block_.get("name") == "SendMessage":
                    has_send = True
            elif btype == "text" and block_.get("text", "").strip():
                did_work = True
    return has_send, did_work


def main():
    raw = sys.stdin.read()
    try:
        data = json.loads(raw)
    except Exception:
        allow("unparseable stdin")

    transcript_path = data.get("transcript_path")
    session_id = data.get("session_id", "unknown")
    agent_id = data.get("agent_id", "unknown")
    agent_type = data.get("agent_type", "unknown")

    if not transcript_path or not os.path.exists(transcript_path):
        allow("no transcript_path")

    try:
        rows = read_transcript(transcript_path)
    except Exception as e:
        allow("transcript read error: %s" % e)

    has_send, did_work = sent_message_since_last_inbound(rows)

    if has_send:
        # Reported correctly — clear nudge state and let it idle.
        clear_state(session_id, agent_id)
        allow()

    if not did_work:
        # Nothing happened this cycle (e.g. ack/shutdown ping). Don't nag.
        allow("no work this cycle")

    nudges = bump_state(session_id, agent_id)
    if nudges > MAX_NUDGES:
        clear_state(session_id, agent_id)
        allow("max nudges reached for %s/%s" % (agent_type, agent_id))

    block(
        "REPORT BEFORE IDLE: You did work this turn but never called "
        "SendMessage, so your result will be LOST — the lead (the agent that "
        "spawned you) only sees a content-free idle ping. Call SendMessage now "
        "with `to` set to the lead and your full completion summary as the "
        "message, THEN go idle. This is mandatory; a prose summary in your "
        "reply does not reach the lead."
    )


def _state_file(session_id, agent_id):
    safe = "%s__%s.json" % (session_id, agent_id)
    safe = safe.replace("/", "_")
    return os.path.join(STATE_DIR, safe)


def bump_state(session_id, agent_id):
    path = _state_file(session_id, agent_id)
    n = 0
    try:
        if os.path.exists(path):
            with open(path) as f:
                n = json.load(f).get("nudges", 0)
    except Exception:
        n = 0
    n += 1
    try:
        os.makedirs(STATE_DIR, exist_ok=True)
        with open(path, "w") as f:
            json.dump({"nudges": n}, f)
    except Exception:
        pass
    return n


def clear_state(session_id, agent_id):
    try:
        os.remove(_state_file(session_id, agent_id))
    except Exception:
        pass


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception as e:
        # Absolute backstop: never trap a teammate.
        log({"decision": "allow", "reason": "uncaught: %s" % e})
        sys.exit(0)
