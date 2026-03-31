#!/usr/bin/env python3
"""Preview a Claude Code session as a markdown conversation, rendered by glow."""
import json
import os
import glob
import sys
from datetime import datetime

sid = sys.argv[1] if len(sys.argv) > 1 else ""
if not sid:
    print("No session ID provided")
    sys.exit(1)

SKIP_TAGS = ("<local-command", "<system-reminder", "<command-name>")


def extract_text(content):
    """Extract display text from a message content field, skipping tool calls."""
    if isinstance(content, str):
        return content.strip()
    if isinstance(content, list):
        parts = []
        for c in content:
            if not isinstance(c, dict):
                continue
            if c.get("type") == "text" and c.get("text", "").strip():
                parts.append(c["text"].strip())
        return "\n\n".join(parts)
    return ""


projects_dir = os.path.expanduser("~/.claude/projects")

for f in glob.glob(os.path.join(projects_dir, "*", f"{sid}.jsonl")):
    proj_dir = os.path.basename(os.path.dirname(f))
    project_path = "/" + proj_dir.lstrip("-").replace("-", "/")

    mtime = os.path.getmtime(f)
    modified = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
    ctime = os.path.getctime(f)
    created = datetime.fromtimestamp(ctime).strftime("%Y-%m-%d %H:%M")

    # Output as markdown
    md = []
    md.append(f"**Session** `{sid}`  ")
    md.append(f"**Project** `{project_path}`  ")
    md.append(f"**Date** {created} → {modified}")
    md.append("")
    md.append("---")
    md.append("")

    try:
        with open(f) as jf:
            for line in jf:
                try:
                    msg = json.loads(line)
                except Exception:
                    continue

                msg_type = msg.get("type")

                if msg_type == "user":
                    content = msg.get("message", {}).get("content", "")
                    text = extract_text(content)
                    if not text or len(text) < 3:
                        continue
                    if any(tag in text for tag in SKIP_TAGS):
                        continue
                    md.append("### 🧑 You")
                    md.append("")
                    md.append(text)
                    md.append("")

                elif msg_type == "assistant":
                    content = msg.get("message", {}).get("content", [])
                    text = extract_text(content)
                    if not text:
                        continue
                    md.append("### 🤖 Claude")
                    md.append("")
                    md.append(text)
                    md.append("")

    except Exception:
        pass

    print("\n".join(md))
    sys.exit(0)

print(f"Session {sid} not found")
