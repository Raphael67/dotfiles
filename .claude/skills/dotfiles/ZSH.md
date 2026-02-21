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
export ZSH=$HOME/.oh-my-zsh
plugins=(evalcache tmux zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh
```

### Installed Plugins

| Plugin | Purpose |
|--------|---------|
| `evalcache` | Cache expensive command outputs |
| `tmux` | Tmux integration and auto-start |
| `zsh-syntax-highlighting` | Command syntax coloring |
| `zsh-autosuggestions` | Fish-like suggestions |

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
if [[ -d "$NVM_DIR" ]]; then
  nvm() {
    unset -f nvm node npm npx
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm "$@"
  }
  for cmd in node npm npx; do
    eval "${cmd}() { unset -f nvm node npm npx; nvm use default --silent; command ${cmd} \"\$@\" }"
  done
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
- `zoxide init zsh --cmd cd`
- `starship init zsh`
- `gh copilot alias -- zsh`
- `jenv init -` (via lazy loading)
- `pyenv init -` (via lazy loading)

**Clear cache:** Delete `~/.zsh-evalcache/`

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
alias gaa="git add -A"
alias gc="git commit"
alias gco="git checkout"
alias gp="git push"
alias gl="git pull"
alias gst="git status"
alias lg="lazygit"
```

**Navigation:**
```zsh
alias doc="cd ~/Documents"
alias dow="cd ~/Downloads"
```

**Quick Commit Function:**
```zsh
qc() {
  # Extracts ticket ID from branch name
  local branch=$(git rev-parse --abbrev-ref HEAD)
  local ticket=$(echo "$branch" | grep -oE '[A-Z]+-[0-9]+')
  git add -A
  if [[ -n "$ticket" ]]; then
    git commit -m "$ticket: $1"
  else
    git commit -m "$1"
  fi
}
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

```zsh
# Disable path underlines (can be slow)
typeset -A ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[path]=none
ZSH_HIGHLIGHT_STYLES[path_prefix]=none
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

## Tmux Auto-Start

```zsh
if [[ -z "$TMUX" && "$TERM_PROGRAM" != "vscode" && -z "$NO_TMUX" && "$CLAUDECODE" != "1" ]]; then
  ZSH_TMUX_AUTOSTART=true
  tmux attach -t main 2>/dev/null || tmux new -s main
fi
```

**Bypass conditions:**
- Already in tmux (`$TMUX` set)
- In VS Code terminal (`$TERM_PROGRAM` = "vscode")
- `NO_TMUX` environment variable set
- Running under Claude Code (`$CLAUDECODE` = "1")

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
# Detailed startup timing breakdown
zsh-startuptime() {
  for i in $(seq 1 5); do
    /usr/bin/time zsh -i -c exit 2>&1
  done
}

# Neovim startup profiling
nvim-startuptime() {
  nvim --startuptime /tmp/nvim-startuptime.log -c 'quit'
  sort -k2 -n /tmp/nvim-startuptime.log | tail -20
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
