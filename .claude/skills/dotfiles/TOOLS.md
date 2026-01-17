# CLI Tools Reference

Secondary tools configured in this dotfiles repository.

## bat (cat replacement)

### Configuration

```
dotfiles/dot-config/bat/config -> ~/.config/bat/config
```

### Current Setup

```bash
# In dot-zshrc
alias cat="bat --style=plain --paging=auto"

# Colored man pages
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
export MANROFFOPT="-c"

# Help function
help() {
    "$@" --help 2>&1 | bat --plain --language=help
}
```

### Common Options

```bash
bat file.txt                    # View with syntax highlighting
bat --style=plain file.txt      # No decorations
bat --style=full file.txt       # All decorations
bat -l json file                # Force language
bat --list-themes               # Show available themes
bat --list-languages            # Show supported languages
```

### Themes

```bash
# Set theme
export BAT_THEME="OneHalfDark"

# Or in config file
--theme="OneHalfDark"
```

---

## eza (ls replacement)

### Current Aliases

```bash
# In dot-zshrc
alias ls="eza -g -s Name --group-directories-first --time-style long-iso --icons=auto"
alias l="ls -la"
alias la="ls -la -a"
alias ll="ls -l"
```

### Options Explained

| Flag | Effect |
|------|--------|
| `-g` | Show group |
| `-s Name` | Sort by name |
| `--group-directories-first` | Directories at top |
| `--time-style long-iso` | ISO date format |
| `--icons=auto` | Show file icons |
| `-l` | Long format |
| `-a` | Show hidden files |

### Additional Options

```bash
eza --tree                      # Tree view
eza --tree --level=2            # Limited depth tree
eza --git                       # Show git status
eza --git-ignore                # Respect .gitignore
eza -lah --git                  # Full details with git
```

---

## fzf (fuzzy finder)

### Configuration

```bash
# In dot-zshrc (Catppuccin colors)
export FZF_DEFAULT_OPTS=" \
  --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 \
  --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 \
  --color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 \
  --color=selected-bg:#494d64 \
  --multi"
```

### Basic Usage

```bash
# Interactive file search
fzf

# Pipe input
cat file | fzf

# Preview files
fzf --preview 'bat --color=always {}'
```

### Shell Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl + R` | Search command history |
| `Ctrl + T` | Search files |
| `Alt + C` | Search and cd to directory |

### Git Integration Aliases

```bash
# In aliases.zsh
alias gafzf='git ls-files -m -o --exclude-standard | fzf --multi | xargs git add'
alias gcofzf='git branch | fzf | xargs git checkout'
alias grfzf='git branch -r | fzf | sed "s/origin\///" | xargs git checkout'
```

---

## zoxide (cd replacement)

### Configuration

```bash
# In dot-zshrc
_evalcache zoxide init zsh --cmd cd
```

This replaces `cd` with zoxide's smart navigation.

### Usage

```bash
cd dirname          # Normal cd behavior
cd pattern          # Jump to frecent match
cd pat1 pat2        # Multiple patterns
cdi                 # Interactive selection with fzf
```

### Commands

```bash
zoxide add /path    # Add path to database
zoxide remove /path # Remove path
zoxide query pat    # Show match without jumping
zoxide query -l     # List all entries
```

### How It Works

Zoxide tracks directory visits and uses "frecency" (frequency + recency) to rank matches. More visited and recently visited directories rank higher.

---

## lazygit

### Configuration

```
dotfiles/dot-config/lazygit/config.yml -> ~/.config/lazygit/config.yml
```

### Shell Setup

```bash
# In dot-zshrc
export COLORTERM=truecolor
export XDG_CONFIG_HOME="$HOME/.config"

# Fix for true colors in tmux
alias lazygit='env TERM=screen-256color lazygit'
alias lg='lazygit'
```

### Key Bindings

| Key | Action |
|-----|--------|
| `space` | Stage/unstage file |
| `a` | Stage all |
| `c` | Commit |
| `p` | Pull |
| `P` | Push |
| `b` | Branches panel |
| `s` | Stash panel |
| `?` | Help |
| `q` | Quit |

### Configuration Options

```yaml
# config.yml
gui:
  theme:
    lightTheme: false
git:
  paging:
    colorArg: always
    pager: delta --dark --paging=never
```

---

## Karabiner Elements

### Configuration

```
dotfiles/dot-config/karabiner/karabiner.json -> ~/.config/karabiner/karabiner.json
```

### Common Modifications

```json
{
  "description": "Caps Lock to Escape",
  "manipulators": [{
    "type": "basic",
    "from": { "key_code": "caps_lock" },
    "to": [{ "key_code": "escape" }]
  }]
}
```

### Current Modifications

| From | To |
|------|-----|
| Caps Lock | Escape |
| Right Cmd + h/j/k/l | Arrow keys |

### Complex Modifications

Karabiner can do much more:
- Dual-function keys (tap for one thing, hold for another)
- App-specific bindings
- Mouse button remapping

### Troubleshooting

1. Check permissions in System Preferences > Security & Privacy
2. Ensure karabiner_console_user_server is running
3. See [GitHub issue #3620](https://github.com/pqrs-org/Karabiner-Elements/issues/3620) for common problems

---

## Nushell

### Configuration

```
dotfiles/dot-config/nushell/config.nu -> ~/.config/nushell/config.nu
dotfiles/dot-config/nushell/env.nu -> ~/.config/nushell/env.nu
```

### Key Differences from Bash/Zsh

| Concept | Bash/Zsh | Nushell |
|---------|----------|---------|
| Output | Text streams | Structured data (tables) |
| Variables | `$var` | `$var` (typed) |
| Pipes | Byte streams | Typed data |
| Filtering | grep | `where` |
| Redirects | `>`, `>>` | `out>`, `out>>` |

### Configuration Pattern

```nushell
# Modify individual settings
$env.config.show_banner = false
$env.config.buffer_editor = "nvim"

# NOT this (resets other settings)
$env.config = { show_banner: false }
```

### Common Commands

```nushell
# List files as table
ls | where size > 1mb

# JSON manipulation
open file.json | get key.nested

# System info
sys | get host

# HTTP requests
http get https://api.example.com | get data
```

### Starship Integration

```nushell
# In config.nu
$env.STARSHIP_SHELL = "nu"
def create_left_prompt [] { starship prompt }
$env.PROMPT_COMMAND = { create_left_prompt }
```

---

## Bitwarden CLI

### Installation

Already in Brewfile:
```bash
brew install bitwarden-cli
```

### Authentication

```bash
# Interactive login
bw login

# API key login (for scripts)
bw login --apikey

# Unlock vault (required after login)
bw unlock

# Export session key
export BW_SESSION=$(bw unlock --raw)
```

### Key Commands

| Command | Description |
|---------|-------------|
| `bw status` | Check login/lock status |
| `bw sync` | Sync vault from server |
| `bw list items` | List all items |
| `bw list items --search term` | Search items |
| `bw get item name` | Get full item |
| `bw get password name` | Get password only |
| `bw get username name` | Get username only |
| `bw get totp name` | Get TOTP code |
| `bw generate -uln --length 24` | Generate password |

### Shell Helper Functions

Add to `~/.config/zsh/bitwarden.zsh`:

```zsh
# Check vault status
bw-status() {
    bw status | jq -r '.status'
}

# Unlock vault
bw-unlock() {
    local status=$(bw-status)
    case "$status" in
        "unlocked")
            echo "Already unlocked"
            ;;
        "locked")
            export BW_SESSION=$(bw unlock --raw)
            [ -n "$BW_SESSION" ] && echo "Unlocked" || echo "Failed"
            ;;
        "unauthenticated")
            echo "Please run: bw login"
            return 1
            ;;
    esac
}

# Lock vault
bw-lock() {
    bw lock && unset BW_SESSION
}

# Get password by name
bwp() {
    [ -z "$BW_SESSION" ] && { echo "Run bw-unlock first" >&2; return 1; }
    bw get password "$1" 2>/dev/null || echo "Not found: $1" >&2
}

# Get username by name
bwu() {
    [ -z "$BW_SESSION" ] && { echo "Run bw-unlock first" >&2; return 1; }
    bw get username "$1" 2>/dev/null || echo "Not found: $1" >&2
}

# Copy password to clipboard
bwc() {
    [ -z "$BW_SESSION" ] && { echo "Run bw-unlock first" >&2; return 1; }
    bw get password "$1" 2>/dev/null | pbcopy && echo "Copied to clipboard"
}

# List items matching search
bwl() {
    [ -z "$BW_SESSION" ] && { echo "Run bw-unlock first" >&2; return 1; }
    bw list items --search "$1" | jq -r '.[] | "\(.name) [\(.id)]"'
}
```

### Environment Variables

| Variable | Purpose |
|----------|---------|
| `BW_SESSION` | Session key for unlocked vault |
| `BW_CLIENTID` | API key client ID |
| `BW_CLIENTSECRET` | API key client secret |

### Security Considerations

- Never commit `BW_SESSION` or API keys to dotfiles
- Session keys expire on `bw lock` or terminal close
- Use `--passwordfile` with `chmod 400` for automation
- API keys still require `unlock` with master password

---

## GitHub CLI (gh)

### Copilot Integration

```bash
# In dot-zshrc (if gh copilot is installed)
if type gh &>/dev/null && gh copilot --version &>/dev/null; then
  _evalcache gh copilot alias -- zsh
  alias '??'='ghcs -t shell'
  alias '?git'='ghcs -t git'
  alias '?gh'='ghcs -t gh'
  alias '?h'='ghce'
fi
```

### Usage

```bash
??  "find large files"       # Shell command suggestion
?git "undo last commit"      # Git command suggestion
?gh "create a release"       # GitHub CLI suggestion
?h                           # Explain last command
```

---

## btop (System Monitor)

### Configuration

```
dotfiles/dot-config/btop/btop.conf -> ~/.config/btop/btop.conf
```

### Launch

```bash
btop
```

### Key Bindings

| Key | Action |
|-----|--------|
| `h` | Help |
| `m` | Toggle memory graph |
| `n` | Toggle network graph |
| `p` | Toggle process list |
| `q` | Quit |

---

## ranger (File Manager)

### Launch

```bash
ranger
# or alias
alias ra='ranger'
```

### Navigation

| Key | Action |
|-----|--------|
| `h/j/k/l` | Navigate |
| `Enter` | Open file |
| `q` | Quit |
| `S` | Open shell in current directory |
| `space` | Select file |
| `yy` | Copy |
| `dd` | Cut |
| `pp` | Paste |
