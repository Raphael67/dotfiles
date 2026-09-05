# Global Claude Configuration

## Environment

- Shell: zsh + oh-my-zsh (source `~/.zshrc` to load nvm) · Terminal: Ghostty · Editor: VSCode
- System packages: Homebrew · Node: nvm only — never `npm install -g` without nvm active
- Timezone: Europe/Paris

## Universal Preferences

- **Git**: never run `git commit`/`git push` from the main loop — always delegate to the `commit` subagent (hook-enforced). All commit rules (atomic commits, conventional messages, tests, fixups) live in that agent.
- **Skills**: never modify a skill without an explicit user request.
- **Planning**: before presenting any non-trivial plan or design, invoke `grill-me` (one question at a time).
- **Questions**: use AskUserQuestion, exactly one question per turn — never batched lists.
- **Agents**: prefer named subagents; after an agent's final report, terminate it (`shutdown_request`). For long-running parallel agents the user should watch, prefer `/pthread` (mprocs) over background subagents.
- **Dependencies**: ask before installing new packages.
- **Build/test failures**: fix the issue, never skip or ignore it.
- **Verifying fixes**: reproduce the user's exact context (cwd, env files, shell) — never test in a sanitized environment.
- **Test runs**: never launch duplicate identical test commands — one foreground run, or a single background run.
- **Files**: generated files are never committed; temp files go to the session scratchpad or OS temp; persistent scripts in TypeScript > Python.
- **Docs**: keep READMEs concise and practical.
- **Rules/CLAUDE.md/memory**: keep atemporal — no dates, commit hashes, or
  "recently fixed X" narration. State the current rule/fact only;
  git log/blame is the history.

## Secrets

- Never hardcode, log, echo, or commit a secret. Secrets are injected at runtime via `bw-inject` (never through Claude's stdout); discovery via `bw-fetch search`/`meta` only — full usage in the `bitwarden-expert` skill.
- A secret needed in a `.env` file requires user confirmation first.

## Tools

- `rtk`: transparent PreToolUse hook rewrites commands for token savings. Meta commands: `rtk gain`, `rtk discover`, `rtk proxy <cmd>`.
- Bash security: damage-control hook (allow/confirm/block) — config in `~/.claude/hooks/damage-control/`.
- Lost/corrupted file recovery: `file-recovery` skill · manual code intelligence: `gitnexus-*` skills · `sem`: entity-level diff/impact — prefer over `git diff` for "what does this change touch" reasoning.
- Browser automation: prefer `claude-in-chrome` over `pw-fast`; ask the user to launch Chrome if needed.
- **Repository exploration**: when exploring external repos, clone them into /tmp rather than using browser tools. Use git and local file tools for analysis.
