# /// script
# requires-python = ">=3.8"
# dependencies = ["pyyaml"]
# ///
"""
Claude Code Edit Tool Damage Control
=====================================

Three-state decision hook for PreToolUse (Edit tool).
Loads patterns from patterns.yaml for easy customization.

Output (JSON to stdout):
  {"decision": "allow"}                        - allow silently
  {"decision": "confirm", "reason": "..."}     - ask user confirmation
  {"decision": "block", "reason": "..."}       - block immediately

Exit codes:
  0 = Normal exit (decision communicated via JSON)
  1 = Error (invalid input)
"""

import json
import sys
from typing import Dict, Any, Tuple

# Add script directory to path for common import
sys.path.insert(0, str(__import__('pathlib').Path(__file__).parent))
from common import match_path, load_config


def check_path(file_path: str, config: Dict[str, Any]) -> Tuple[str, str]:
    """Check if file_path should be blocked, confirmed, or allowed.

    Returns: (decision, reason)
      - ("block", reason): Block the edit immediately
      - ("confirm", reason): Ask user for confirmation
      - ("allow", ""): Allow the edit silently
    """
    for zero_path in config.get("zeroAccessPaths", []):
        if match_path(file_path, zero_path):
            return "block", f"zero-access path {zero_path} (no operations allowed)"

    for readonly in config.get("readOnlyPaths", []):
        if match_path(file_path, readonly):
            return "block", f"read-only path {readonly}"

    for confirm_path in config.get("confirmPaths", []):
        if match_path(file_path, confirm_path):
            return "confirm", f"Editing {file_path} requires approval (matches confirmPaths pattern: {confirm_path})"

    return "allow", ""


def main() -> None:
    config = load_config()

    try:
        input_data = json.load(sys.stdin)
    except json.JSONDecodeError as e:
        print(f"Error: Invalid JSON input: {e}", file=sys.stderr)
        sys.exit(1)

    tool_name = input_data.get("tool_name", "")
    tool_input = input_data.get("tool_input", {})

    if tool_name != "Edit":
        sys.exit(0)

    file_path = tool_input.get("file_path", "")
    if not file_path:
        sys.exit(0)

    decision, reason = check_path(file_path, config)

    if decision == "block":
        output = {
            "decision": "block",
            "reason": f"[HOOK:damage-control] SECURITY: Blocked edit to {reason}: {file_path}"
        }
        print(json.dumps(output))
        sys.exit(0)
    elif decision == "confirm":
        output = {
            "decision": "confirm",
            "reason": f"[HOOK:damage-control] {reason}"
        }
        print(json.dumps(output))
        sys.exit(0)
    else:
        output = {"decision": "allow"}
        print(json.dumps(output))
        sys.exit(0)


if __name__ == "__main__":
    main()
