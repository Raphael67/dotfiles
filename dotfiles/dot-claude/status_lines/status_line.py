#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///

"""
Status Line - Context Window + Rate Limits
Display: [Model] # 42.5% used | ~115k left | 5h: 23% 2h30m | 7d: 8% 6d12h | session_id
"""

import json
import os
import sys
from datetime import datetime, timezone

# Force UTF-8 output on Windows (avoids charmap codec errors with Unicode chars)
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")

CACHE_PATH = os.path.join(os.environ.get("TMPDIR", "/tmp"), "claude_rate_limits.json")

# ANSI color codes
CYAN = "\033[36m"
GREEN = "\033[32m"
YELLOW = "\033[33m"
RED = "\033[31m"
DIM = "\033[90m"
BLUE = "\033[34m"
MAGENTA = "\033[35m"
RESET = "\033[0m"
BRIGHT_RED = "\033[91m"


def get_usage_color(percentage):
    if percentage < 50:
        return GREEN
    elif percentage < 75:
        return YELLOW
    elif percentage < 90:
        return RED
    return BRIGHT_RED


def get_window_usage_color(used_pct, resets_at, window_seconds):
    """
    Color the used percentage relative to elapsed time in the window.

    Thresholds:
      - GREEN  if used_pct <= elapsed_pct              (consuming slower than time)
      - ORANGE if elapsed_pct < used_pct <= elapsed_pct + remaining_pct / 2
      - RED    if used_pct > elapsed_pct + remaining_pct / 2
    """
    ORANGE = "\033[38;5;208m"
    if not resets_at or not window_seconds:
        return get_usage_color(used_pct)
    try:
        if isinstance(resets_at, (int, float)):
            reset_dt = datetime.fromtimestamp(resets_at, tz=timezone.utc)
        else:
            reset_dt = datetime.fromisoformat(str(resets_at).replace("Z", "+00:00"))
        remaining_seconds = (reset_dt - datetime.now(timezone.utc)).total_seconds()
        remaining_seconds = max(0.0, remaining_seconds)
        remaining_pct = (remaining_seconds / window_seconds) * 100
        elapsed_pct = 100 - remaining_pct
        low_threshold = elapsed_pct
        high_threshold = elapsed_pct + remaining_pct / 2
        if used_pct <= low_threshold:
            return GREEN
        elif used_pct <= high_threshold:
            return ORANGE
        else:
            return RED
    except (ValueError, TypeError, OSError):
        return get_usage_color(used_pct)


def create_progress_bar(percentage, width=15):
    filled = int((percentage / 100) * width)
    empty = width - filled
    color = get_usage_color(percentage)
    return f"[{color}{'#' * filled}{DIM}{'-' * empty}{RESET}]"


def format_tokens(tokens):
    if tokens is None:
        return "0"
    if tokens < 1000:
        return str(int(tokens))
    elif tokens < 1000000:
        return f"{tokens / 1000:.1f}k"
    return f"{tokens / 1000000:.2f}M"


def format_reset_time(resets_at):
    if not resets_at:
        return None
    try:
        if isinstance(resets_at, (int, float)):
            reset_dt = datetime.fromtimestamp(resets_at, tz=timezone.utc)
        else:
            reset_dt = datetime.fromisoformat(str(resets_at).replace("Z", "+00:00"))
        delta = reset_dt - datetime.now(timezone.utc)
        total_seconds = int(delta.total_seconds())
        if total_seconds <= 0:
            return "now"
        if total_seconds < 3600:
            return f"{total_seconds // 60}m"
        return f"{total_seconds // 3600}h{(total_seconds % 3600) // 60:02d}m"
    except (ValueError, TypeError, OSError):
        return None


def format_subscription_time(resets_at):
    """Format remaining subscription time: 'XdYh' if >= 24h, else 'XhYm'."""
    if not resets_at:
        return None
    try:
        if isinstance(resets_at, (int, float)):
            reset_dt = datetime.fromtimestamp(resets_at, tz=timezone.utc)
        else:
            reset_dt = datetime.fromisoformat(str(resets_at).replace("Z", "+00:00"))
        delta = reset_dt - datetime.now(timezone.utc)
        total_seconds = int(delta.total_seconds())
        if total_seconds <= 0:
            return "expired"
        total_hours = total_seconds // 3600
        remaining_minutes = (total_seconds % 3600) // 60
        if total_hours >= 24:
            days = total_hours // 24
            hours = total_hours % 24
            return f"{days}d{hours}h"
        return f"{total_hours}h{remaining_minutes}m"
    except (ValueError, TypeError, OSError):
        return None


def load_cached_rate_limits():
    try:
        with open(CACHE_PATH) as f:
            return json.load(f)
    except (OSError, json.JSONDecodeError):
        return None


def save_rate_limits_cache(rate_limits):
    try:
        with open(CACHE_PATH, "w") as f:
            json.dump(rate_limits, f)
    except OSError:
        pass


def get_rate_limits(input_data):
    rate_limits = input_data.get("rate_limits")
    if rate_limits and isinstance(rate_limits, dict):
        save_rate_limits_cache(rate_limits)
        return rate_limits
    return load_cached_rate_limits()


def generate_status_line(input_data):
    model_name = input_data.get("model", {}).get("display_name", "Claude")
    session_id = input_data.get("session_id", "") or "--------"

    context_data = input_data.get("context_window", {})
    used_pct = context_data.get("used_percentage", 0) or 0
    ctx_size = context_data.get("context_window_size", 200000) or 200000
    remaining = int(ctx_size * ((100 - used_pct) / 100))

    parts = [
        f"{CYAN}[{model_name}]{RESET}",
        f"{MAGENTA}#{RESET} {get_usage_color(used_pct)}{used_pct:.1f}%{RESET} used",
        f"{BLUE}~{format_tokens(remaining)} left{RESET}",
    ]

    # Rate limits (5h and 7d windows)
    rate_limits = get_rate_limits(input_data)
    if rate_limits:
        window_durations = {"five_hour": 5 * 3600, "seven_day": 7 * 24 * 3600}
        for key, label in [("five_hour", "5h"), ("seven_day", "7d")]:
            window = rate_limits.get(key)
            if not window or not isinstance(window, dict):
                continue
            pct = window.get("used_percentage")
            if pct is None:
                continue
            pct = float(pct)
            color = get_window_usage_color(pct, window.get("resets_at"), window_durations[key])
            indicator = f"{DIM}{label}:{RESET} {color}{pct:.0f}%{RESET}"
            reset = format_subscription_time(window.get("resets_at"))
            if reset:
                indicator += f" {DIM}{reset}{RESET}"
            parts.append(indicator)

    parts.append(f"{DIM}{session_id}{RESET}")
    return " | ".join(parts)


def main():
    try:
        input_data = json.loads(sys.stdin.read())
        print(generate_status_line(input_data))
    except json.JSONDecodeError:
        print(f"{RED}[Claude] # Error: Invalid JSON{RESET}")
    except Exception as e:
        print(f"{RED}[Claude] # Error: {e}{RESET}")


if __name__ == "__main__":
    main()
