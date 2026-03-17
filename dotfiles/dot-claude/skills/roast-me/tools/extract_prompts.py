#!/usr/bin/env python3
"""Extract user prompts from Claude Code conversation logs for quality analysis.

Scans ~/.claude/projects/*/*.jsonl for recent sessions and extracts user prompts
with context about what happened after each prompt (errors, corrections, etc.).

Outputs /tmp/roast-me-extracted.json with structured prompt records.
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

MAX_PROMPTS = 300
PROMPT_TEXT_LIMIT = 1500
CORRECTION_TEXT_LIMIT = 500
ERROR_TEXT_LIMIT = 500
CONTEXT_BEFORE_LIMIT = 500  # Previous assistant message for context


def find_session_files(days: int, project: str | None = None) -> list[Path]:
    """Find all .jsonl session files modified within the last N days."""
    claude_dir = Path.home() / ".claude" / "projects"
    if not claude_dir.exists():
        return []

    cutoff = time.time() - (days * 86400)
    files = []

    search_dirs = [claude_dir]
    if project:
        project_dir = claude_dir / project
        if project_dir.exists():
            search_dirs = [project_dir]

    for search_dir in search_dirs:
        for jsonl in search_dir.rglob("*.jsonl"):
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
    parent = session_file.parent.name
    if parent.startswith("-"):
        return "/" + parent[1:].replace("-", "/")
    return parent


def extract_user_text(content) -> str:
    """Extract text from a user message's content field."""
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts = []
        for block in content:
            if isinstance(block, dict) and block.get("type") == "text":
                parts.append(block.get("text", ""))
        return "\n".join(parts)
    return ""


def is_meta_message(obj: dict) -> bool:
    """Check if a user message is a meta/system message."""
    msg = obj.get("message", {})
    if msg.get("isMeta"):
        return True
    content = msg.get("content", [])
    if isinstance(content, list):
        # Skip messages that are only tool_result blocks (no user text)
        has_text = any(
            isinstance(b, dict) and b.get("type") == "text"
            for b in content
        )
        has_tool_result = any(
            isinstance(b, dict) and b.get("type") == "tool_result"
            for b in content
        )
        if has_tool_result and not has_text:
            return True
    return False


def process_session(session_file: Path) -> list[dict]:
    """Process a single session file and extract user prompt records."""
    messages = []

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

    # Build ordered list of (line_num, msg_type, obj)
    ordered = []
    for line_num, obj in messages:
        msg_type = obj.get("type")
        if msg_type in ("user", "assistant"):
            ordered.append((line_num, msg_type, obj))

    # First pass: count total user prompts (non-meta)
    user_prompt_indices = []
    for i, (line_num, msg_type, obj) in enumerate(ordered):
        if msg_type == "user" and not is_meta_message(obj):
            user_text = extract_user_text(obj.get("message", {}).get("content", []))
            if user_text.strip():
                user_prompt_indices.append(i)

    total_prompts = len(user_prompt_indices)
    prompts = []

    for position, idx in enumerate(user_prompt_indices, 1):
        line_num, _, obj = ordered[idx]
        content = obj.get("message", {}).get("content", [])
        prompt_text = extract_user_text(content)
        timestamp = obj.get("timestamp", "")

        # Analyze structure
        has_xml_tags = bool(re.search(r"<\w+>", prompt_text))
        has_file_paths = bool(re.search(r"[/\\][\w./\\-]+\.\w+", prompt_text))
        has_code_blocks = "```" in prompt_text

        # Get context: previous assistant message (what Claude said before this prompt)
        context_before = ""
        for j in range(idx - 1, -1, -1):
            _, prev_type, prev_obj = ordered[j]
            if prev_type == "assistant":
                prev_content = prev_obj.get("message", {}).get("content", [])
                if isinstance(prev_content, list):
                    for block in prev_content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            context_before += block.get("text", "")
                break

        # Look ahead for assistant response and errors/corrections
        followed_by_error = False
        error_was_recovered = False  # Agent continued successfully after error
        followed_by_correction = False
        correction_text = ""
        error_tool = ""
        error_text = ""
        assistant_tool_count = 0
        assistant_text_length = 0
        error_count = 0
        success_after_error = 0

        # Scan assistant messages until next user prompt
        for j in range(idx + 1, len(ordered)):
            j_line, j_type, j_obj = ordered[j]

            if j_type == "assistant":
                a_content = j_obj.get("message", {}).get("content", [])
                if isinstance(a_content, list):
                    for block in a_content:
                        if isinstance(block, dict):
                            if block.get("type") == "tool_use":
                                assistant_tool_count += 1
                            elif block.get("type") == "text":
                                assistant_text_length += len(block.get("text", ""))

            elif j_type == "user":
                # Check if this user message is a tool_result with error
                u_content = j_obj.get("message", {}).get("content", [])
                if isinstance(u_content, list):
                    for block in u_content:
                        if not isinstance(block, dict) or block.get("type") != "tool_result":
                            continue
                        if block.get("is_error"):
                            error_count += 1
                            if not followed_by_error:
                                followed_by_error = True
                                # Find matching tool_use
                                tid = block.get("tool_use_id")
                                for k in range(j - 1, idx, -1):
                                    _, kt, ko = ordered[k]
                                    if kt == "assistant":
                                        ac = ko.get("message", {}).get("content", [])
                                        if isinstance(ac, list):
                                            for ab in ac:
                                                if (isinstance(ab, dict)
                                                        and ab.get("type") == "tool_use"
                                                        and ab.get("id") == tid):
                                                    error_tool = ab.get("name", "")
                                                    break
                                # Extract error text
                                rc = block.get("content", [])
                                if isinstance(rc, list):
                                    for rb in rc:
                                        if isinstance(rb, dict) and rb.get("type") == "text":
                                            error_text = rb.get("text", "")
                                            break
                                elif isinstance(rc, str):
                                    error_text = rc
                        else:
                            # Successful tool result after an error = recovery
                            if error_count > 0:
                                success_after_error += 1

                # Check if this is the next real user message (non-meta with text)
                if not is_meta_message(j_obj):
                    next_text = extract_user_text(u_content)
                    if next_text.strip():
                        if CORRECTION_PATTERNS.search(next_text):
                            followed_by_correction = True
                            correction_text = next_text
                        break  # Stop at next user prompt

        # Error was recovered if agent had successful tool calls after the error
        # and user didn't need to correct
        error_was_recovered = (
            followed_by_error
            and success_after_error > 0
            and not followed_by_correction
        )

        prompts.append({
            "session_file": str(session_file),
            "line_number": line_num,
            "timestamp": timestamp,
            "project_path": project_path,
            "prompt_text": truncate(prompt_text, PROMPT_TEXT_LIMIT),
            "prompt_length": len(prompt_text),
            "prompt_position": position,
            "total_prompts_in_session": total_prompts,
            "has_xml_tags": has_xml_tags,
            "has_file_paths": has_file_paths,
            "has_code_blocks": has_code_blocks,
            "followed_by_error": followed_by_error,
            "error_was_recovered": error_was_recovered,
            "followed_by_correction": followed_by_correction,
            "correction_text": truncate(correction_text, CORRECTION_TEXT_LIMIT),
            "error_tool": error_tool,
            "error_text": truncate(error_text, ERROR_TEXT_LIMIT),
            "assistant_tool_count": assistant_tool_count,
            "assistant_text_length": assistant_text_length,
            "context_before": truncate(context_before, CONTEXT_BEFORE_LIMIT),
        })

    return prompts


def main():
    parser = argparse.ArgumentParser(
        description="Extract user prompts from Claude Code conversation logs"
    )
    parser.add_argument(
        "--days", type=int, default=7, help="Number of days to look back (default: 7)"
    )
    parser.add_argument(
        "--project", type=str, default=None,
        help="Encoded project path to filter (e.g., -Users-foo-bar)"
    )
    parser.add_argument(
        "--output", type=str, default="/tmp/roast-me-extracted.json",
        help="Output file path",
    )
    args = parser.parse_args()

    session_files = find_session_files(args.days, args.project)
    if not session_files:
        print(f"No session files found in the last {args.days} days.", file=sys.stderr)
        result = {"prompts": [], "metadata": {
            "sessions_scanned": 0, "projects_scanned": 0,
            "total_prompts": 0, "error_rate": 0, "correction_rate": 0,
            "avg_length": 0, "xml_usage_rate": 0,
        }}
        with open(args.output, "w") as f:
            json.dump(result, f, indent=2)
        print(f"Wrote empty result to {args.output}")
        return

    projects = set()
    all_prompts = []

    for sf in session_files:
        projects.add(extract_project_path(sf))
        prompts = process_session(sf)
        all_prompts.extend(prompts)

    # Prioritize prompts that caused errors/corrections, then cap
    error_prompts = [p for p in all_prompts if p["followed_by_error"] or p["followed_by_correction"]]
    normal_prompts = [p for p in all_prompts if not p["followed_by_error"] and not p["followed_by_correction"]]
    all_prompts = (error_prompts + normal_prompts)[:MAX_PROMPTS]

    total = len(all_prompts)
    errors = sum(1 for p in all_prompts if p["followed_by_error"])
    recovered = sum(1 for p in all_prompts if p["error_was_recovered"])
    unrecovered = errors - recovered
    corrections = sum(1 for p in all_prompts if p["followed_by_correction"])
    avg_length = sum(p["prompt_length"] for p in all_prompts) / total if total else 0
    xml_count = sum(1 for p in all_prompts if p["has_xml_tags"])

    result = {
        "prompts": all_prompts,
        "metadata": {
            "sessions_scanned": len(session_files),
            "projects_scanned": len(projects),
            "total_prompts": total,
            "error_rate": round(errors / total, 3) if total else 0,
            "recovered_error_rate": round(recovered / total, 3) if total else 0,
            "effective_error_rate": round(unrecovered / total, 3) if total else 0,
            "correction_rate": round(corrections / total, 3) if total else 0,
            "avg_length": round(avg_length, 1),
            "xml_usage_rate": round(xml_count / total, 3) if total else 0,
            "file_path_rate": round(
                sum(1 for p in all_prompts if p["has_file_paths"]) / total, 3
            ) if total else 0,
        },
    }

    with open(args.output, "w") as f:
        json.dump(result, f, indent=2)

    print(f"Scanned {len(session_files)} sessions across {len(projects)} projects")
    print(f"Extracted {total} prompts ({errors} with errors, {recovered} auto-recovered, {unrecovered} impactful)")
    print(f"Corrections: {corrections} | Avg length: {avg_length:.0f} chars | XML: {xml_count}/{total}")
    print(f"Output: {args.output}")


if __name__ == "__main__":
    main()
