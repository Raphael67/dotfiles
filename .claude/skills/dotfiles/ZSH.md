# Zsh Configuration Reference

## This Repository's Structure

| File | Location | Purpose |
|------|----------|---------|
| `dot-zshrc` | `~/.zshrc` | Main shell configuration |
| `dot-zprofile` | `~/.zprofile` | Login shell setup |
| `dot-config/zsh/aliases.zsh` | `~/.config/zsh/aliases.zsh` | All aliases |

## Startup File Order

Zsh loads files in this order:

```
1. /etc/zshenv      (always, system-wide)
2. ~/.zshenv        (always, user)
3. /etc/zprofile    (login shells only)
4. ~/.zprofile      (login shells only)
5. /etc/zshrc       (interactive shells only)
6. ~/.zshrc         (interactive shells only)
7. /etc/zlogin      (login shells only)
8. ~/.zlogin        (login shells only)
```

**Best Practice:**
- `.zshenv` - Environment variables needed everywhere
- `.zprofile` - Login-specific setup (rarely needed)
- `.zshrc` - Interactive config (aliases, prompt, completion)

## XDG Environment Variables

Set early in `dot-zshrc` to ensure all tools respect XDG paths:

```zsh
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_CACHE_HOME="$HOME/.cache"
```

Tools that use these:
- **Oh-My-Zsh**: `export ZSH="$XDG_DATA_HOME/oh-my-zsh"`
- **NVM**: `export NVM_DIR="$XDG_DATA_HOME/nvm"`
- **Zsh history**: `HISTFILE="$XDG_STATE_HOME/zsh/history"`
- **evalcache**: `ZSH_EVALCACHE_DIR="$XDG_CACHE_HOME/zsh-evalcache"`

## Oh-My-Zsh Configuration

### Current Setup

```zsh
# In dot-zshrc
export ZSH="${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh"
# Fallback: use legacy path if XDG path doesn't exist yet
[[ ! -d "$ZSH" && -d "$HOME/.oh-my-zsh" ]] && export ZSH="$HOME/.oh-my-zsh"

plugins=(evalcache tmux fzf-tab zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
```

### Installed Plugins

| Plugin | Purpose |
|--------|---------|
| `evalcache` | Cache expensive command outputs |
| `tmux` | Tmux integration and auto-start |
| `zsh-syntax-highlighting` | Command syntax coloring |
| `zsh-autosuggestions` | Fish-like suggestions |
| `fzf-tab` | Fuzzy tab completion (replaces default zsh tab) |

### Adding Custom Plugins

1. Clone to custom plugins directory:
   ```bash
   git clone https://github.com/user/plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/plugin-name
   ```

2. Add to plugins array in `dot-zshrc`:
   ```zsh
   plugins=(... plugin-name)
   ```

3. Reload: `source ~/.zshrc`

## Lazy Loading Pattern

Version managers are lazy-loaded to improve shell startup time:

```zsh
# jenv (Java)
if [[ -d "$HOME/.jenv" ]]; then
  jenv() {
    unset -f jenv
    export PATH="$HOME/.jenv/bin:$PATH"
    _evalcache jenv init -
    jenv "$@"
  }
fi

# pyenv (Python)
if [[ -d "$HOME/.pyenv" ]]; then
  pyenv() {
    unset -f pyenv
    export PYENV_ROOT="$HOME/.pyenv"
    [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
    _evalcache pyenv init -
    pyenv "$@"
  }
fi
```

# nvm (Node.js) — ~300ms savings
# Eagerly adds default node version to PATH, then lazy-loads nvm
if [[ -d "$NVM_DIR" || -d "/opt/homebrew/opt/nvm" ]]; then
  # Add default node version to PATH immediately (no nvm load)
  if [[ -d "$NVM_DIR/versions/node" ]]; then
    local default_node=$(ls -1 "$NVM_DIR/versions/node" | sort -V | tail -1)
    [[ -n "$default_node" ]] && export PATH="$NVM_DIR/versions/node/$default_node/bin:$PATH"
  fi

  nvm() {
    unset -f nvm node npm npx
    # Supports both Homebrew and standard nvm paths
    if [[ -s "/opt/homebrew/opt/nvm/nvm.sh" ]]; then
      export NVM_DIR="/opt/homebrew/opt/nvm"
      \. "/opt/homebrew/opt/nvm/nvm.sh"
    elif [[ -s "$NVM_DIR/nvm.sh" ]]; then
      \. "$NVM_DIR/nvm.sh"
    fi
    nvm "$@"
  }
  node() { unset -f node; nvm use --lts --silent 2>/dev/null; node "$@"; }
  npm() { unset -f npm; nvm use --lts --silent 2>/dev/null; npm "$@"; }
  npx() { unset -f npx; nvm use --lts --silent 2>/dev/null; npx "$@"; }
fi
```

### How It Works

1. Function with same name as command is defined
2. First call removes the function (`unset -f`)
3. Initializes the actual tool
4. Forwards the call with arguments

## evalcache Plugin

Caches expensive command outputs to speed up shell startup:

```zsh
# Instead of:
eval "$(zoxide init zsh --cmd cd)"

# Use:
_evalcache zoxide init zsh --cmd cd
```

**Currently cached:**
- `zoxide init zsh --cmd cd` (skipped under Claude Code)
- `starship init zsh`
- `jenv init -` (via lazy loading)
- `pyenv init -` (via lazy loading)
- `atuin init zsh`
- `direnv hook zsh`
- `tv init zsh`

**Clear cache:** Delete `$XDG_CACHE_HOME/zsh-evalcache/`

## History Configuration

```zsh
HISTSIZE=1000000
SAVEHIST=1000000

setopt HIST_EXPIRE_DUPS_FIRST  # Expire duplicates first
setopt HIST_IGNORE_DUPS        # Don't record consecutive duplicates
setopt HIST_IGNORE_ALL_DUPS    # Remove older duplicate entries
setopt HIST_IGNORE_SPACE       # Don't record lines starting with space
setopt HIST_SAVE_NO_DUPS       # Don't write duplicates to file
setopt HIST_FIND_NO_DUPS       # Don't show duplicates in search
setopt HIST_REDUCE_BLANKS      # Remove extra blanks
setopt EXTENDED_HISTORY        # Save timestamps
setopt SHARE_HISTORY           # Share between sessions
```

## Aliases

Aliases are defined in `dotfiles/dot-config/zsh/aliases.zsh`.

### Current Alias Categories

**Git:**
```zsh
alias g="git"
alias ga="git add"
alias gap="git add --patch"
alias gb="git branch"
alias gc="git commit -v"
alias gcl="git clone"
alias gco="git checkout"
alias gd="git diff ..."
alias gds="git diff --staged"
alias gf="git fetch"
alias gl="git log --all --graph ..."   # Pretty graph log
alias gm="git merge"
alias gp="git push"
alias gpo="git push origin"
alias gs="git status --short --branch"
alias gu="git pull"
alias gup="git fetch && git rebase"
alias lg="lazygit"
```

**fzf-powered Git:**
```zsh
alias gafzf='...'    # Git add with fzf multi-select
alias gcofzf='...'   # Checkout branch with fzf
alias grfzf='...'    # Git restore with fzf
alias grsfzf='...'   # Git restore --staged with fzf
alias grmfzf='...'   # Git rm with fzf
```

**Quick Commit Function:**
```zsh
quick_commit() {
  # Extracts ticket ID from branch name (e.g., PROJ-123)
  local branch_name=$(git branch --show-current)
  local ticket_id=$(echo "$branch_name" | awk -F '-' '{print toupper($1"-"$2)}')
  # Supports optional "push" as first arg
  if [[ "$1" == "push" ]]; then
    git commit --no-verify -m "$ticket_id: ${*:2}" && git push
  else
    git commit --no-verify -m "$ticket_id: $*"
  fi
}
alias gqc='quick_commit'
alias gqcp='quick_commit push'
```

**Neovim:**
```zsh
alias v='poetry_run_nvim'   # Uses poetry run nvim if in poetry project
alias vi='poetry_run_nvim'
```

**Misc:**
```zsh
alias c='clear'
alias e='exit'
alias r='. ranger'
alias oo='...'           # Open Obsidian vault in nvim
alias notmux='...'       # New Ghostty window without tmux
alias news='...'         # HYS RSS reader (last 48h)
alias fixmouse='...'     # Reset stuck mouse reporting mode
alias clyo='claude --dangerously-skip-permissions'
```

### Adding New Aliases

1. Edit `dotfiles/dot-config/zsh/aliases.zsh`
2. Add alias:
   ```zsh
   alias myalias="command"
   ```
3. Reload: `source ~/.zshrc`

### Adding Functions

For complex logic, use functions instead of aliases:

```zsh
myfunction() {
  local arg1="$1"
  # Complex logic here
  echo "Result: $arg1"
}
```

## zsh-autosuggestions Configuration

```zsh
# Suggestion strategy (history first, then completion)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Clear suggestions on these widgets
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(bracketed-paste)
ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=(backward-delete-char)
```

**Accept suggestion:** Right arrow or End key

## zsh-syntax-highlighting Configuration

Full Catppuccin Macchiato theme applied with ~30 style entries. Key settings:

```zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main cursor)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=#8aadf4'        # blue
ZSH_HIGHLIGHT_STYLES[alias]='fg=#a6da95'           # green
ZSH_HIGHLIGHT_STYLES[builtin]='fg=#ed8796'         # red
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=#ed8796'   # red
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=#a6da95'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=#a6da95'
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none
# ... plus ~20 more Catppuccin-themed entries
```

## Key Bindings

```zsh
# Edit command in $EDITOR
bindkey '^f' edit-command-line

# Reduce escape key delay (for vi mode)
KEYTIMEOUT=1
```

## Shell Options

```zsh
unsetopt LIST_BEEP    # No beeps on tab completion
```

## Tool Integrations

### Starship Prompt
```zsh
export STARSHIP_CONFIG=~/.config/starship/starship.toml
_evalcache starship init zsh
```

### Zoxide (cd replacement)
```zsh
_evalcache zoxide init zsh --cmd cd
```

### fzf (fuzzy finder)
```zsh
export FZF_DEFAULT_OPTS="..."  # Catppuccin colors
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
```

### atuin (shell history)
```zsh
# Replaces Ctrl+R with a full-text searchable history database
_evalcache atuin init zsh
```

Config: `~/.config/atuin/config.toml`
- Search mode: fuzzy (default), also supports prefix, fulltext, skim
- Filter mode: global (Ctrl+R), host-only (Up arrow)
- Workspace mode: git-aware directory filtering
- Secrets auto-filter: AWS keys, GitHub tokens, etc.

| Key | Action |
|-----|--------|
| `Ctrl+R` | Open atuin interactive search |
| `Up arrow` | Scroll history (filtered to current host) |
| `Enter` | Execute selected command |
| `Tab` | Return to shell for editing |

### direnv (per-directory env vars)
```zsh
_evalcache direnv hook zsh
```

Config: `~/.config/direnv/direnv.toml`, `~/.config/direnv/direnvrc`
- Auto-loads `.envrc` and `.env` files when entering a directory
- Auto-unloads when leaving
- `~/Projects` is whitelisted (auto-trusted)
- Custom stdlib: `use_nvm`, `use_pyenv`, `layout_uv`

### television (TUI data browser)
```zsh
_evalcache tv init zsh
```

Config: `~/.config/television/config.toml`, cable channels in `~/.config/television/cable/`
- Smart autocomplete: type a command then `Ctrl+T` to pick contextually
- Channel triggers: `git checkout` + `Ctrl+T` opens git-branch channel
- Custom cable channels: brew-packages, docker-containers, git-*, gh-prs, k8s-pods, claude-sessions
- Theme: Catppuccin

### fzf-tab (fuzzy tab completion)

Replaces zsh's default tab completion with fzf. Configured via zstyle in `dot-zshrc`:

- `cd` tab: directory preview with eza
- `cat`/`nvim` tab: file preview with bat
- `git checkout` tab: git log preview
- `kill` tab: process details preview
- `brew` tab: brew info preview
- `Ctrl+Space`: multi-select
- `<`/`>`: switch completion groups
- `/`: continuous directory completion

### eza (ls replacement)
```zsh
alias ls="eza -g -s Name --group-directories-first --time-style long-iso --icons=auto"
alias l="ls -la"
alias la="ls -la -a"
alias ll="ls -l"
```

### bat (cat replacement)
```zsh
alias cat="bat --style=plain --paging=auto"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
```

## Tmux Auto-Start (Disabled)

Currently commented out in dot-zshrc. Use manual start:

```bash
tmux attach -t main || tmux new -s main
```

The `notmux` alias opens a Ghostty window without tmux.

## Shell Style Guidelines

### Quoting

```zsh
# Always quote variables
echo "$variable"           # Correct
echo $variable             # Wrong - word splitting issues

# Single quotes for literals
echo 'literal string'

# Exception: these never need quotes
echo $$                    # PID
echo $?                    # Exit status
echo $#                    # Argument count
```

### Tests

```zsh
# Use [[ ]] instead of [ ]
[[ -f "$file" ]]          # Correct
[ -f "$file" ]            # Works but less safe

# Use (( )) for arithmetic
(( count > 5 ))           # Correct
[[ $count -gt 5 ]]        # Also works
```

### Functions

```zsh
# Use this syntax
myfunction() {
  local var="$1"          # Always use local
  # ...
}

# Not this
function myfunction {     # Non-POSIX
  # ...
}
```

### Error Handling

```zsh
# Check commands that can fail
cd /path || exit 1
cd /path || { echo "Failed"; return 1; }

# Don't rely on set -e (causes issues)
```

## Debugging

### Timing Startup

```bash
# Quick timing
zsh-time                  # alias for: time zsh -i -c exit

# Detailed profiling
zsh-debug                 # alias for: time ZSH_DEBUG=1 zsh -i -c exit
```

### Profiling with zprof

Add to top of `.zshrc`:
```zsh
zmodload zsh/zprof
```

Add to bottom:
```zsh
zprof
```

### Verbose Loading

```bash
zsh -xv 2>&1 | tee ~/zsh-debug.log
```

### Startup Profiling Functions

```zsh
# Average startup time (10 runs)
zsh-startuptime() {
  local total=0
  for i in $(seq 1 10); do
    local t=$({ time zsh -i -c exit; } 2>&1 | grep real | awk '{print $2}' | sed 's/[^0-9.]//g')
    total=$(echo "$total + $t" | bc)
  done
  echo "average: $(echo "scale=3; $total / 10" | bc)s (10 runs)"
}

# Verbose profiling with zprof
zsh-startuptime-verbose() {
  zsh -i -c "zprof" 2>/dev/null
}

# Neovim startup profiling
nvim-startuptime() {
  nvim --headless --startuptime /tmp/nvim-startuptime.log -c 'qall' && \
    tail -1 /tmp/nvim-startuptime.log && \
    rm /tmp/nvim-startuptime.log
}
```

### Startup Cleanup Notes

- Duplicate `compinit` calls removed (Oh-My-Zsh handles it)
- OpenJDK PATH export consolidated into jenv lazy loader
- `NVM_DIR` set via XDG, no longer defaults to `~/.nvm`

## Common Customizations

### Change Prompt

Use Starship (already configured). Edit `~/.config/starship/starship.toml`.

### Add PATH Entry

```zsh
# In dot-zshrc
export PATH="$HOME/mybin:$PATH"

# For unique entries (already at end of dot-zshrc)
typeset -U path PATH
```

### Environment Variables

```zsh
# In dot-zshrc or ~/.env
export MY_VAR="value"
```

### Completion Settings

```zsh
# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# Menu selection
zstyle ':completion:*' menu select

# Colored completions
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
```
