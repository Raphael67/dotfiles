"""Sync ~/.claude/skills/ into the installed Cowork plugin's skills/ directory.

Cowork mounts a plugin's `skills/` directory read-only into the VM at session
boot. To expose host skills to Cowork, we copy them into the installed
plugin tree as real files (the VM cannot follow symlinks pointing outside the
plugin tree).

Run via the `cowork-skills` zsh function. After running, restart Claude Desktop
for the new snapshot to take effect inside new Cowork sessions.
"""
from __future__ import annotations

import os
import shutil
import sys
from pathlib import Path

SKILLS_DIR = Path(os.environ.get("COWORK_SKILLS_DIR", "~/.claude/skills")).expanduser()
COWORK_ROOT = Path(
    "~/Library/Application Support/Claude/local-agent-mode-sessions"
).expanduser()
PLUGIN_DIRNAME = "plugin_claude-code-skills-bridge"

# Skills bundled by Cowork's anthropic-skills plugin — don't duplicate.
COWORK_BUNDLED = {
    "docx", "pdf", "pptx", "xlsx", "skill-creator",
    "schedule", "setup-cowork", "consolidate-memory",
}


def active_rpm_dir() -> Path | None:
    """Return the rpm/ directory of the *live* Cowork tree.

    The layout is .../local-agent-mode-sessions/<userId>/<orgId>/rpm/. Both
    levels change when the signed-in account or organization changes, and the
    old trees are left behind on disk. Picking the first match found would
    target a dead tree, so select the rpm/ whose manifest.json was written most
    recently. Directories renamed to *.preexisting.bak.* are Cowork's own
    backups and are never live.
    """
    if not COWORK_ROOT.exists():
        return None
    candidates: list[tuple[float, Path]] = []
    for user_dir in COWORK_ROOT.iterdir():
        if not user_dir.is_dir() or user_dir.name == "skills-plugin":
            continue
        for org_dir in user_dir.iterdir():
            if not org_dir.is_dir() or ".preexisting.bak." in org_dir.name:
                continue
            manifest = org_dir / "rpm" / "manifest.json"
            if manifest.is_file():
                candidates.append((manifest.stat().st_mtime, org_dir / "rpm"))
    if not candidates:
        return None
    return max(candidates, key=lambda c: c[0])[1]


def _find_installed_plugin() -> Path | None:
    """Locate the installed plugin inside the live Cowork tree."""
    rpm = active_rpm_dir()
    if rpm is None:
        return None
    candidate = rpm / PLUGIN_DIRNAME
    return candidate if candidate.is_dir() else None


def _is_cowork_bundled_symlink(skill_dir: Path) -> bool:
    """True if the skill dir is a symlink into Claude Desktop's own skills-plugin."""
    if not skill_dir.is_symlink():
        return False
    target = str(skill_dir.resolve())
    return "local-agent-mode-sessions/skills-plugin" in target


def _eligible_skills() -> list[Path]:
    if not SKILLS_DIR.exists():
        return []
    out: list[Path] = []
    for entry in sorted(SKILLS_DIR.iterdir()):
        if entry.name.startswith(".") or entry.name in COWORK_BUNDLED:
            continue
        if _is_cowork_bundled_symlink(entry):
            continue
        if not (entry / "SKILL.md").exists():
            continue
        out.append(entry)
    return out


def _copy_real_files(src: Path, dst: Path) -> int:
    """Copy src tree to dst, resolving symlinks at every level."""
    count = 0
    for root, _, files in os.walk(src, followlinks=True):
        rel = Path(root).relative_to(src)
        (dst / rel).mkdir(parents=True, exist_ok=True)
        for name in files:
            sp = Path(root) / name
            dp = dst / rel / name
            try:
                shutil.copy2(sp, dp, follow_symlinks=True)
                count += 1
            except (OSError, shutil.SameFileError) as exc:
                print(f"  WARN: copy failed {sp} -> {dp}: {exc}", file=sys.stderr)
    return count


def main() -> int:
    plugin = _find_installed_plugin()
    if plugin is None:
        print(
            f"ERROR: installed plugin not found under {COWORK_ROOT}.\n"
            f"Run ~/.config/cowork-skills/install.sh first to copy the plugin into Cowork.",
            file=sys.stderr,
        )
        return 1

    target = plugin / "skills"
    print(f"cowork-skills sync")
    print(f"  source : {SKILLS_DIR}")
    print(f"  target : {target}")
    print()

    if target.exists():
        shutil.rmtree(target)
    target.mkdir(parents=True)

    skills = _eligible_skills()
    total_files = 0
    for skill in skills:
        n = _copy_real_files(skill, target / skill.name)
        print(f"  + {skill.name:30s}  ({n} files)")
        total_files += n

    excluded = sorted(s for s in COWORK_BUNDLED if (SKILLS_DIR / s).exists())
    if excluded:
        print(f"\nExcluded (already bundled by Cowork): {', '.join(excluded)}")

    print(
        f"\nSynced {len(skills)} skills, {total_files} files total.\n"
        f"\nNext step:\n"
        f"  Restart Claude Desktop.\n"
        f"  Inside Cowork, your skills appear as 'claude-code-skills-bridge:<name>'.\n"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
