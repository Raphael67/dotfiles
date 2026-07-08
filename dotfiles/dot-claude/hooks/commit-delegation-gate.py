# /// script
# requires-python = ">=3.8"
# dependencies = []
# ///
"""
Commit-delegation gate (PreToolUse / Bash)
==========================================

Problem this solves
-------------------
The workflow rule is: `git commit` / `git push` must be delegated to the
dedicated `commit` subagent, not run directly by the main loop. The main agent
routinely forgets and commits itself.

What this hook does
-------------------
Fires on every Bash tool call. If the command runs `git commit` or `git push`
AND the caller is the MAIN LOOP, it blocks (permissionDecision: deny) and tells
the model to delegate to the `commit` subagent. Any subagent is allowed through
untouched.

How "main loop" is detected
---------------------------
Claude Code includes `agent_type` in the hook input ONLY when the call comes
from a subagent (`--agent` or a spawned teammate). The main loop has no
`agent_type`. So: field absent/empty -> main loop -> gate applies; field present
-> some subagent -> allow.

RTK interaction
--------------
A separate PreToolUse hook (`rtk hook claude`) rewrites commands, e.g.
`git commit` -> `rtk git commit`. The regex below matches a "git commit" /
"git push" invocation anywhere in the string, so it catches both the raw and
rtk-prefixed forms regardless of hook ordering.

Safety
------
FAILS OPEN: unparseable stdin, missing fields, or any unexpected error ->
exit 0 (allow). A gate that wrongly blocks is worse than the bug it guards.
"""
import json
import re
import sys
from typing import NoReturn

# Matches a `git commit` / `git push` INVOCATION — anchored to command position
# (start of string or just after a separator: ; && || | newline), with an
# optional wrapper prefix (`rtk `, `sudo `). Anchoring is deliberate: it catches
# real invocations (`git commit`, `rtk git push`, `cd x && git commit`) but NOT
# mere mentions inside quotes/args (`-m "git commit"`, `grep "git push"`,
# `echo "... git commit ..."`), which would otherwise block innocent commands.
GIT_WRITE_RE = re.compile(
    r"(?:^|[\n;&|])\s*(?:sudo\s+)?(?:rtk\s+)?git\s+(?:commit|push)\b",
    re.IGNORECASE,
)

DENY_REASON = (
    "Delegate git commit/push to the `commit` subagent. The main loop must not "
    "commit or push directly — spawn the `commit` agent "
    "(Agent with subagent_type: 'commit') and let it stage, group, and commit. "
    "This block only applies to the main loop; the commit agent runs freely. "
    "If you genuinely need to bypass (e.g. the agent itself is unavailable), "
    "tell the user and let them run the git command via `!` in the prompt."
)


def allow() -> NoReturn:
    """Permit the tool call (silent)."""
    sys.exit(0)


def deny(reason: str) -> NoReturn:
    """Block the tool call and feed `reason` back to the model."""
    print(
        json.dumps(
            {
                "hookSpecificOutput": {
                    "hookEventName": "PreToolUse",
                    "permissionDecision": "deny",
                    "permissionDecisionReason": reason,
                }
            }
        )
    )
    sys.exit(0)


def main() -> None:
    try:
        data = json.loads(sys.stdin.read())
    except Exception:
        allow()  # fail open

    if not isinstance(data, dict):
        allow()

    # agent_type present and non-empty => a subagent is calling => allow.
    agent_type = data.get("agent_type")
    if isinstance(agent_type, str) and agent_type.strip():
        allow()

    command = data.get("tool_input", {}).get("command", "")
    if not isinstance(command, str) or not command:
        allow()

    if GIT_WRITE_RE.search(command):
        deny(DENY_REASON)

    allow()


if __name__ == "__main__":
    try:
        main()
    except SystemExit:
        raise
    except Exception:
        # Absolute backstop: never block on an unexpected error.
        sys.exit(0)
