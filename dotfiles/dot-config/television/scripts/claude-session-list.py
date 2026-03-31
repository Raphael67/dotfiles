#!/usr/bin/env python3
"""List all Claude Code sessions by scanning JSONL files directly.

Outputs tab-separated: session_id\t[datetime] title\tsearchable_text
Television fuzzy-finds against the full raw line, so all user prompts are
appended to make the full conversation searchable.
"""
import json
import os
import glob
from datetime import datetime

home = os.path.expanduser("~")
projects_dir = os.path.join(home, ".claude", "projects")
entries = []

SKIP_TAGS = ("<local-command", "<system-reminder", "<command-name>")


def extract_user_text(content):
    """Extract clean text from a user message content field."""
    if isinstance(content, list):
        content = " ".join(
            c.get("text", "") for c in content if isinstance(c, dict)
        )
    elif not isinstance(content, str):
        content = str(content)
    if any(tag in content for tag in SKIP_TAGS):
        return ""
    return content.strip()


def extract_assistant_text(content):
    """Extract text blocks from an assistant message (skip tool_use/thinking)."""
    if not isinstance(content, list):
        return ""
    parts = []
    for c in content:
        if isinstance(c, dict) and c.get("type") == "text" and c.get("text", "").strip():
            parts.append(c["text"].strip()[:200])
    return " ".join(parts)


def read_jsonl_texts(jsonl_path):
    """Read all user+assistant messages from a JSONL file. Returns (first_prompt, all_text)."""
    first_prompt = ""
    all_texts = []
    try:
        with open(jsonl_path) as jf:
            for line in jf:
                try:
                    msg = json.loads(line)
                except Exception:
                    continue
                msg_type = msg.get("type")
                if msg_type == "user":
                    text = extract_user_text(msg.get("message", {}).get("content", ""))
                    if not text or len(text) < 5:
                        continue
                    if not first_prompt:
                        first_prompt = text[:80]
                    all_texts.append(text[:200])
                elif msg_type == "assistant":
                    text = extract_assistant_text(msg.get("message", {}).get("content", []))
                    if text:
                        all_texts.append(text[:200])
    except Exception:
        pass
    return first_prompt, " ".join(all_texts)


for f in glob.glob(os.path.join(projects_dir, "*", "*.jsonl")):
    sid = os.path.basename(f).replace(".jsonl", "")
    try:
        mtime = os.path.getmtime(f)
        modified = datetime.fromtimestamp(mtime).strftime("%Y-%m-%dT%H:%M:%S")
        first_prompt, search_text = read_jsonl_texts(f)
        name = first_prompt.replace("\t", " ").replace("\n", " ").rstrip("\u2026").strip()
        if not name:
            name = "(no title)"
        dt = modified[:16].replace("T", " ")
        search_text = " ".join(search_text.split()).replace("\t", " ")
        # ANSI dim the search text so it's matchable but visually subtle
        DIM = "\033[2m"
        RESET = "\033[0m"
        entries.append((modified, f"{sid}\t[{dt}] {name} {DIM}{search_text}{RESET}"))
    except Exception:
        pass

entries.sort(key=lambda x: x[0], reverse=True)
for _, line in entries:
    print(line)
