#!/usr/bin/env python3
"""Extract tool errors and user corrections from Claude Code conversation logs.

Scans ~/.claude/projects/*//*.jsonl for recent sessions and extracts:
- Tool errors (is_error: true)
- User corrections (messages containing correction patterns)

Outputs /tmp/self-healing-extracted.json with structured extractions.
"""

import argparse
import json
import os
import re
import sys
import time
from collections import defaultdict
from pathlib import Path

CORRECTION_PATTERNS = re.compile(
    r"\b(no[,.]?\s|wrong|instead|actually|don'?t|shouldn'?t|stop|not that|"
    r"I said|I meant|I asked|that'?s not|please don'?t|why did you|"
    r"you should have|that was wrong|incorrect|try again|redo|"
    r"that broke|you broke|revert|undo)\b",
    re.IGNORECASE,
)

MAX_EXTRACTIONS = 500
TOOL_INPUT_LIMIT = 500
RESULT_LIMIT = 1000
USER_MSG_LIMIT = 500


def find_session_files(days: int) -> list[Path]:
    """Find all .jsonl session files modified within the last N days."""
    claude_dir = Path.home() / ".claude" / "projects"
    if not claude_dir.exists():
        return []

    cutoff = time.time() - (days * 86400)
    files = []
    for jsonl in claude_dir.rglob("*.jsonl"):
        try:
            if jsonl.stat().st_mtime >= cutoff:
                files.append(jsonl)
        except OSError:
            continue
    return sorted(files, key=lambda f: f.stat().st_mtime, reverse=True)


def truncate(s: str, limit: int) -> str:
    if not s or len(s) <= limit:
        return s or ""
    return s[:limit] + "..."


def extract_project_path(session_file: Path) -> str:
    """Derive project path from session file location."""
    # ~/.claude/projects/<encoded-project-path>/<session-id>.jsonl
    parent = session_file.parent.name
    # Decode the path: -Users-foo-bar -> /Users/foo/bar
    if parent.startswith("-"):
        return "/" + parent[1:].replace("-", "/")
    return parent


def process_session(session_file: Path) -> list[dict]:
    """Process a single session file and extract issues."""
    extractions = []
    messages = []  # (line_number, parsed_obj)

    try:
        with open(session_file, "r", encoding="utf-8", errors="replace") as f:
            for line_num, line in enumerate(f, 1):
                line = line.strip()
                if not line:
                    continue
                try:
                    obj = json.loads(line)
                    messages.append((line_num, obj))
                except json.JSONDecodeError:
                    continue
    except OSError:
        return []

    project_path = extract_project_path(session_file)

    # Index tool_use blocks by tool_use_id (from assistant messages)
    tool_uses = {}  # tool_use_id -> (line_num, tool_use_block)
    # Ordered list of (line_num, msg_type, obj) for sequential scanning
    ordered = []

    for line_num, obj in messages:
        msg_type = obj.get("type")

        if msg_type == "assistant":
            ordered.append((line_num, "assistant", obj))
            content = obj.get("message", {}).get("content", [])
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "tool_use":
                        tid = block.get("id")
                        if tid:
                            tool_uses[tid] = (line_num, block)

        elif msg_type == "user":
            ordered.append((line_num, "user", obj))
            # Tool results are embedded as content blocks in user messages
            content = obj.get("message", {}).get("content", [])
            if isinstance(content, list):
                for block in content:
                    if not isinstance(block, dict) or block.get("type") != "tool_result":
                        continue
                    is_error = block.get("is_error", False)
                    if not is_error:
                        continue

                    tool_use_id = block.get("tool_use_id")
                    tool_use_info = tool_uses.get(tool_use_id)
                    if not tool_use_info:
                        continue

                    use_line, use_block = tool_use_info
                    tool_name = use_block.get("name", "unknown")
                    tool_input = json.dumps(use_block.get("input", {}))

                    # Extract result text from tool_result content
                    result_content = block.get("content", [])
                    result_text = ""
                    if isinstance(result_content, list):
                        for rb in result_content:
                            if isinstance(rb, dict) and rb.get("type") == "text":
                                result_text += rb.get("text", "")
                    elif isinstance(result_content, str):
                        result_text = result_content

                    # Find next user text message after this line
                    next_user_msg = ""
                    for ol, ot, oo in ordered:
                        if ol > line_num and ot == "user":
                            uc = oo.get("message", {}).get("content", [])
                            if isinstance(uc, list):
                                for ub in uc:
                                    if isinstance(ub, dict) and ub.get("type") == "text":
                                        next_user_msg += ub.get("text", "")
                            elif isinstance(uc, str):
                                next_user_msg = uc
                            if next_user_msg:
                                break

                    timestamp = obj.get("timestamp", "")

                    extractions.append({
                        "session_file": str(session_file),
                        "line_number": line_num,
                        "timestamp": timestamp,
                        "project_path": project_path,
                        "tool_name": tool_name,
                        "tool_input": truncate(tool_input, TOOL_INPUT_LIMIT),
                        "result": truncate(result_text, RESULT_LIMIT),
                        "is_error": True,
                        "next_user_message": truncate(next_user_msg, USER_MSG_LIMIT),
                        "type": "tool_error",
                    })

    # Extract user corrections from user text messages
    for i, (line_num, msg_type, obj) in enumerate(ordered):
        if msg_type != "user":
            continue

        content = obj.get("message", {}).get("content", [])
        user_text = ""
        if isinstance(content, list):
            for block in content:
                if isinstance(block, dict) and block.get("type") == "text":
                    user_text += block.get("text", "")
        elif isinstance(content, str):
            user_text = content

        if not user_text or not CORRECTION_PATTERNS.search(user_text):
            continue

        # Get preceding assistant message
        preceding_assistant = ""
        preceding_tool = ""
        for j in range(i - 1, -1, -1):
            prev_line, prev_type, prev_obj = ordered[j]
            if prev_type == "assistant":
                acontent = prev_obj.get("message", {}).get("content", [])
                if isinstance(acontent, list):
                    for block in acontent:
                        if isinstance(block, dict):
                            if block.get("type") == "text":
                                preceding_assistant += block.get("text", "")
                            elif block.get("type") == "tool_use":
                                preceding_tool = block.get("name", "")
                elif isinstance(acontent, str):
                    preceding_assistant = acontent
                break

        timestamp = obj.get("timestamp", "")

        extractions.append({
            "session_file": str(session_file),
            "line_number": line_num,
            "timestamp": timestamp,
            "project_path": project_path,
            "tool_name": preceding_tool or "conversation",
            "tool_input": truncate(preceding_assistant, TOOL_INPUT_LIMIT),
            "result": "",
            "is_error": False,
            "next_user_message": truncate(user_text, USER_MSG_LIMIT),
            "type": "user_correction",
        })

    return extractions


def deduplicate(extractions: list[dict]) -> list[dict]:
    """Deduplicate by (tool_name, error_message_prefix_100chars)."""
    seen = set()
    deduped = []
    for ext in extractions:
        key = (ext["tool_name"], ext["result"][:100])
        if key not in seen:
            seen.add(key)
            deduped.append(ext)
    return deduped


def main():
    parser = argparse.ArgumentParser(
        description="Extract issues from Claude Code conversation logs"
    )
    parser.add_argument(
        "--days", type=int, default=7, help="Number of days to look back (default: 7)"
    )
    parser.add_argument(
        "--output",
        type=str,
        default="/tmp/self-healing-extracted.json",
        help="Output file path",
    )
    args = parser.parse_args()

    session_files = find_session_files(args.days)
    if not session_files:
        print(f"No session files found in the last {args.days} days.", file=sys.stderr)
        result = {"extractions": [], "metadata": {"sessions_scanned": 0, "projects_scanned": 0}}
        with open(args.output, "w") as f:
            json.dump(result, f, indent=2)
        print(f"Wrote empty result to {args.output}")
        return

    # Track unique projects
    projects = set()
    all_extractions = []

    for sf in session_files:
        projects.add(extract_project_path(sf))
        exts = process_session(sf)
        all_extractions.extend(exts)

    # Deduplicate
    all_extractions = deduplicate(all_extractions)

    # Prioritize is_error: true, then cap
    errors = [e for e in all_extractions if e["is_error"]]
    non_errors = [e for e in all_extractions if not e["is_error"]]
    all_extractions = (errors + non_errors)[:MAX_EXTRACTIONS]

    result = {
        "extractions": all_extractions,
        "metadata": {
            "sessions_scanned": len(session_files),
            "projects_scanned": len(projects),
            "total_extractions": len(all_extractions),
            "tool_errors": len([e for e in all_extractions if e["is_error"]]),
            "user_corrections": len([e for e in all_extractions if not e["is_error"]]),
        },
    }

    with open(args.output, "w") as f:
        json.dump(result, f, indent=2)

    print(f"Scanned {len(session_files)} sessions across {len(projects)} projects")
    print(f"Extracted {len(all_extractions)} issues ({result['metadata']['tool_errors']} errors, {result['metadata']['user_corrections']} corrections)")
    print(f"Output: {args.output}")


if __name__ == "__main__":
    main()
