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
from typing import Any

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

# Tier-level fallback pricing (per million tokens) for models not in pricing.json
TIER_FALLBACK_PRICING = {
    "opus": {"input": 5, "output": 25, "cache_write_5m": 6.25, "cache_read": 0.5},
    "sonnet": {"input": 3, "output": 15, "cache_write_5m": 3.75, "cache_read": 0.3},
    "haiku": {"input": 1, "output": 5, "cache_write_5m": 1.25, "cache_read": 0.1},
}

COMPLEXITY_TO_MODEL = {"simple": "haiku", "moderate": "sonnet", "complex": "opus"}
MODEL_TIER_RANK = {"haiku": 0, "sonnet": 1, "opus": 2, "unknown": 1}

# Heuristic patterns for task classification
SIMPLE_PATTERNS = [
    re.compile(p, re.IGNORECASE) for p in [
        r"^\s*(yes|ok|oui|go ahead|looks good|lgtm|sure|do it|yep|yup|correct|exactly|perfect)\s*[.!]?\s*$",
        r"^\s*(commit|push|merge|ship it|deploy)\s*$",
        r"^\s*(read|cat|show|list|ls|find|check)\b.{0,80}$",
        r"^\s*(format|lint|prettier|fix.*style|fix.*indent|add semicolons?)\b",
        r"^\s*(what does|explain|what is|how does|tell me about)\b.{0,120}$",
        r"^\s*(create|make|add|touch)\s+(a\s+)?(new\s+)?(file|dir|directory|folder)\b.{0,80}$",
        r"^\s*(delete|remove|rm)\s+.{0,80}$",
        r"^\s*/\w+",  # slash commands
    ]
]

COMPLEX_PATTERNS = [
    re.compile(p, re.IGNORECASE) for p in [
        r"\b(design|architect|plan|strategy|migration|roadmap)\b",
        r"\b(debug|race\s*condition|memory\s*leak|performance\s*(issue|problem|bug))\b",
        r"\b(implement|build|create)\b.{30,}",  # long implementation requests
        r"\b(multi.?file|across.*codebase|entire|all\s+files)\b",
        r"\b(skill|agent|workflow|pipeline|system)\b.*\b(create|build|design|implement)\b",
        r"\b(refactor|rewrite|overhaul|restructure)\b.*\b(entire|all|whole|codebase)\b",
    ]
]


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


def load_pricing() -> dict[str, dict]:
    """Load model pricing from Claude's pricing.json."""
    pricing_path = Path.home() / ".claude" / "powerline" / "usage" / "pricing.json"
    try:
        with open(pricing_path) as f:
            data = json.load(f).get("data", {})
        return data
    except (OSError, json.JSONDecodeError):
        return {}


def get_model_tier(model_name: str) -> str:
    """Normalize model name to tier: opus, sonnet, haiku."""
    if not model_name:
        return "unknown"
    m = model_name.lower()
    if "opus" in m:
        return "opus"
    if "sonnet" in m:
        return "sonnet"
    if "haiku" in m:
        return "haiku"
    return "unknown"


def estimate_cost(
    model: str,
    input_tokens: int,
    output_tokens: int,
    cache_creation: int,
    cache_read: int,
    pricing: dict[str, dict],
) -> float:
    """Estimate cost in USD for a single API call."""
    # Try exact model match in pricing.json
    p = pricing.get(model)
    if not p:
        # Fallback to tier pricing
        tier = get_model_tier(model)
        p = TIER_FALLBACK_PRICING.get(tier, TIER_FALLBACK_PRICING["sonnet"])

    cost = (
        input_tokens * p["input"]
        + output_tokens * p["output"]
        + cache_creation * p["cache_write_5m"]
        + cache_read * p["cache_read"]
    ) / 1_000_000
    return round(cost, 6)


def estimate_cost_for_tier(
    tier: str,
    input_tokens: int,
    output_tokens: int,
    cache_creation: int,
    cache_read: int,
) -> float:
    """Estimate cost if the same call used a different model tier."""
    p = TIER_FALLBACK_PRICING.get(tier, TIER_FALLBACK_PRICING["sonnet"])
    cost = (
        input_tokens * p["input"]
        + output_tokens * p["output"]
        + cache_creation * p["cache_write_5m"]
        + cache_read * p["cache_read"]
    ) / 1_000_000
    return round(cost, 6)


def classify_task_complexity(prompt_text: str, prompt_length: int,
                             prompt_position: int, tool_count: int) -> str:
    """Heuristic task complexity: simple, moderate, or complex."""
    # Check complex patterns first (they override)
    for pat in COMPLEX_PATTERNS:
        if pat.search(prompt_text):
            return "complex"

    # Check simple patterns
    for pat in SIMPLE_PATTERNS:
        if pat.search(prompt_text):
            return "simple"

    # Fallback heuristics based on length and tool usage
    if prompt_length < 50 and tool_count <= 2:
        return "simple"
    if prompt_length < 200 and tool_count <= 10:
        return "moderate"
    if prompt_length > 500:
        return "complex"

    return "moderate"


def extract_response_compute(ordered: list, idx: int, pricing: dict) -> dict:
    """Extract model, tokens, thinking, and cost from first assistant response."""
    result = {
        "response_model": "",
        "response_model_tier": "unknown",
        "response_input_tokens": 0,
        "response_output_tokens": 0,
        "response_cache_creation_tokens": 0,
        "response_cache_read_tokens": 0,
        "response_has_thinking": False,
        "response_thinking_length": 0,
        "estimated_cost_usd": 0.0,
    }

    # Find first assistant message after this prompt
    for j in range(idx + 1, len(ordered)):
        _, j_type, j_obj = ordered[j]

        if j_type == "user" and not is_meta_message(j_obj):
            # Reached next user prompt without finding assistant — stop
            user_text = extract_user_text(j_obj.get("message", {}).get("content", []))
            if user_text.strip():
                break

        if j_type == "assistant":
            msg = j_obj.get("message", {})
            model = msg.get("model", "")
            usage = msg.get("usage", {})

            result["response_model"] = model
            result["response_model_tier"] = get_model_tier(model)

            input_t = usage.get("input_tokens", 0)
            output_t = usage.get("output_tokens", 0)
            cache_create = usage.get("cache_creation_input_tokens", 0)
            cache_read = usage.get("cache_read_input_tokens", 0)

            result["response_input_tokens"] = input_t
            result["response_output_tokens"] = output_t
            result["response_cache_creation_tokens"] = cache_create
            result["response_cache_read_tokens"] = cache_read

            # Check for thinking blocks
            content = msg.get("content", [])
            if isinstance(content, list):
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "thinking":
                        result["response_has_thinking"] = True
                        thinking_text = block.get("thinking", "")
                        result["response_thinking_length"] += len(thinking_text)

            result["estimated_cost_usd"] = estimate_cost(
                model, input_t, output_t, cache_create, cache_read, pricing
            )
            break  # Only capture first assistant response

    return result


def process_session(session_file: Path, pricing: dict | None = None) -> list[dict]:
    """Process a single session file and extract user prompt records."""
    if pricing is None:
        pricing = {}
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

        # Extract compute data from assistant response
        compute = extract_response_compute(ordered, idx, pricing)

        # Classify task complexity and compute efficiency
        complexity = classify_task_complexity(
            prompt_text, len(prompt_text), position, assistant_tool_count
        )
        recommended = COMPLEXITY_TO_MODEL[complexity]
        actual_tier = compute["response_model_tier"]
        was_overkill = (
            MODEL_TIER_RANK.get(actual_tier, 1)
            > MODEL_TIER_RANK.get(recommended, 1)
        )

        # Estimate what it would have cost with the recommended model
        optimal_cost = estimate_cost_for_tier(
            recommended,
            compute["response_input_tokens"],
            compute["response_output_tokens"],
            compute["response_cache_creation_tokens"],
            compute["response_cache_read_tokens"],
        )

        record = {
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
            # Compute efficiency fields
            **compute,
            "task_complexity": complexity,
            "recommended_model": recommended,
            "compute_was_overkill": was_overkill,
            "optimal_cost_usd": optimal_cost,
        }

        prompts.append(record)

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

    pricing = load_pricing()

    session_files = find_session_files(args.days, args.project)
    if not session_files:
        print(f"No session files found in the last {args.days} days.", file=sys.stderr)
        result = {"prompts": [], "metadata": {
            "sessions_scanned": 0, "projects_scanned": 0,
            "total_prompts": 0, "error_rate": 0, "correction_rate": 0,
            "avg_length": 0, "xml_usage_rate": 0,
        }, "compute_stats": {}}
        with open(args.output, "w") as f:
            json.dump(result, f, indent=2)
        print(f"Wrote empty result to {args.output}")
        return

    projects = set()
    all_prompts = []

    for sf in session_files:
        projects.add(extract_project_path(sf))
        prompts = process_session(sf, pricing)
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

    # Compute stats
    model_dist: dict[str, dict[str, Any]] = {}
    total_cost = 0.0
    total_optimal_cost = 0.0
    thinking_count = 0
    thinking_lengths: list[int] = []
    overkill_count = 0

    saveable_cost = 0.0  # only count savings where optimal < actual

    for p in all_prompts:
        tier = p.get("response_model_tier", "unknown")
        cost = p.get("estimated_cost_usd", 0)
        opt_cost = p.get("optimal_cost_usd", 0)

        if tier not in model_dist:
            model_dist[tier] = {"count": 0, "total_cost": 0.0}
        model_dist[tier]["count"] += 1
        model_dist[tier]["total_cost"] = round(model_dist[tier]["total_cost"] + cost, 6)

        total_cost += cost
        total_optimal_cost += opt_cost

        # Only count savings where we're actually overspending
        if cost > opt_cost:
            saveable_cost += cost - opt_cost

        if p.get("response_has_thinking"):
            thinking_count += 1
            thinking_lengths.append(p.get("response_thinking_length", 0))

        if p.get("compute_was_overkill"):
            overkill_count += 1

    # Add percentages to model distribution
    for tier_data in model_dist.values():
        tier_data["pct"] = round(tier_data["count"] / total, 3) if total else 0
        tier_data["total_cost"] = round(tier_data["total_cost"], 4)

    compute_stats = {
        "model_distribution": model_dist,
        "thinking_usage_rate": round(thinking_count / total, 3) if total else 0,
        "avg_thinking_length": round(sum(thinking_lengths) / len(thinking_lengths)) if thinking_lengths else 0,
        "total_cost_usd": round(total_cost, 4),
        "total_optimal_cost_usd": round(total_optimal_cost, 4),
        "avg_cost_per_prompt_usd": round(total_cost / total, 4) if total else 0,
        "heuristic_overuse_count": overkill_count,
        "heuristic_overuse_rate": round(overkill_count / total, 3) if total else 0,
        "heuristic_savings_usd": round(saveable_cost, 4),
    }

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
        "compute_stats": compute_stats,
    }

    with open(args.output, "w") as f:
        json.dump(result, f, indent=2)

    print(f"Scanned {len(session_files)} sessions across {len(projects)} projects")
    print(f"Extracted {total} prompts ({errors} with errors, {recovered} auto-recovered, {unrecovered} impactful)")
    print(f"Corrections: {corrections} | Avg length: {avg_length:.0f} chars | XML: {xml_count}/{total}")
    print(f"Compute: ${total_cost:.2f} total | ${saveable_cost:.2f} potential savings | {overkill_count} overkill | {thinking_count} with thinking")
    print(f"Models: {', '.join(f'{t}: {d['count']}' for t, d in sorted(model_dist.items()))}")
    print(f"Output: {args.output}")


if __name__ == "__main__":
    main()
