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
# Set theme (Catppuccin Macchiato)
export BAT_THEME="Catppuccin Macchiato"

# Or in config file
--theme="Catppuccin Macchiato"
```

**Install Catppuccin theme:**
```bash
bat cache --build   # Rebuild cache after adding theme files
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
# In dot-zshrc (Catppuccin Macchiato palette)
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
    # Catppuccin Macchiato colors
    activeBorderColor:
      - "#8aadf4"  # blue
      - bold
    inactiveBorderColor:
      - "#a5adcb"  # subtext0
    optionsTextColor:
      - "#8aadf4"  # blue
    selectedLineBgColor:
      - "#363a4f"  # surface0
    cherryPickedCommitBgColor:
      - "#494d64"  # surface1
    cherryPickedCommitFgColor:
      - "#8aadf4"  # blue
    unstagedChangesColor:
      - "#ed8796"  # red
    defaultFgColor:
      - "#cad3f5"  # text
    searchingActiveBorderColor:
      - "#eed49f"  # yellow
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
dotfiles/dot-config/nushell/config.nu -> $XDG_CONFIG_HOME/nushell/config.nu
dotfiles/dot-config/nushell/env.nu -> $XDG_CONFIG_HOME/nushell/env.nu
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

Starship and zoxide are loaded via **vendor autoload** (`$nu.vendor-autoload-dirs`):

```nushell
# Vendor autoload handles starship and zoxide automatically
# No manual config needed — just ensure they're installed

# Manual alternative (if not using vendor autoload):
$env.STARSHIP_SHELL = "nu"
def create_left_prompt [] { starship prompt }
$env.PROMPT_COMMAND = { create_left_prompt }
```

### Advanced Configuration

**Config loading order:** env.nu → config.nu → vendor autoload → user autoload → login.nu

> **Note:** Modern Nushell practice consolidates environment setup into `config.nu` rather than maintaining a separate `env.nu`.

**Important behaviors:**
- `$env.config` settings are **not inherited** by child processes — export variables if they need to persist
- XDG variables (`$env.XDG_CONFIG_HOME`, `$env.XDG_DATA_HOME`, `$env.XDG_DATA_DIRS`) must point to the **parent directory**, not the nushell subdirectory

**Startup flags:**

| Flag | Effect |
|------|--------|
| `nu -n` | Skip all config file loading |
| `nu --no-std-lib` | Standard library unavailable |
| `nu -l` | Login shell (runs login.nu) |
| `nu -n --no-std-lib` | Fastest startup (scripts) |

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

### Theme

Catppuccin Macchiato theme (`color_theme = "catppuccin_macchiato"`).

Theme file: `~/.config/btop/themes/catppuccin_macchiato.theme`

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

## k9s (Kubernetes TUI)

### Configuration

```
dotfiles/dot-config/k9s/skins/ -> ~/.config/k9s/skins/
```

### Theme

Catppuccin Macchiato skin applied via k9s config:

```yaml
# In k9s config
skin: catppuccin_macchiato
```

Skin file provides Catppuccin Macchiato colors for all k9s UI elements.

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

---

## atuin (shell history database)

### Configuration

```
dotfiles/dot-config/atuin/config.toml -> ~/.config/atuin/config.toml
```

### Shell Setup

```zsh
# In dot-zshrc
_evalcache atuin init zsh
```

### Key Bindings

| Key | Action |
|-----|--------|
| `Ctrl+R` | Interactive history search (fuzzy) |
| `Up arrow` | History filtered to current host |
| `Enter` | Execute selected command |
| `Tab` | Return to shell for editing |
| `Ctrl+R` (inside search) | Cycle filter: global → host → session → directory |

### Configuration Highlights

| Setting | Value | Purpose |
|---------|-------|---------|
| `search_mode` | fuzzy | Typo-tolerant matching |
| `filter_mode` | global | Default search all history |
| `filter_mode_shell_up_key_binding` | host | Up arrow = current machine only |
| `workspaces` | true | Git-aware directory filtering |
| `secrets_filter` | true | Auto-filter AWS keys, tokens |
| `enter_accept` | true | Enter runs immediately |

### Commands

```bash
atuin stats              # Most-used commands
atuin search "pattern"   # Search history
atuin import auto        # Import from zsh/bash
```

---

## direnv (per-directory environment)

### Configuration

```
dotfiles/dot-config/direnv/direnv.toml -> ~/.config/direnv/direnv.toml
dotfiles/dot-config/direnv/direnvrc -> ~/.config/direnv/direnvrc
```

### Shell Setup

```zsh
# In dot-zshrc
_evalcache direnv hook zsh
```

### Usage

```bash
cd ~/Projects/myapp     # .envrc auto-loads
cd ~                    # .envrc auto-unloads
direnv allow            # Trust a new/changed .envrc
direnv edit .           # Edit .envrc (auto-allows on save)
```

### Custom stdlib (from direnvrc)

| Function | Usage in .envrc | Purpose |
|----------|----------------|---------|
| `use nvm` | `use nvm` or `use nvm 20` | Auto-switch Node version from .nvmrc |
| `use pyenv` | `use pyenv` or `use pyenv 3.12` | Auto-switch Python from .python-version |
| `layout uv` | `layout uv` | Create/activate uv virtualenv |

### Configuration Highlights

| Setting | Value | Purpose |
|---------|-------|---------|
| `load_dotenv` | true | Auto-load .env files |
| `strict_env` | true | Fail fast on errors |
| `hide_env_diff` | true | Cleaner output |
| `whitelist.prefix` | ~/Projects | Auto-trust project .envrc files |

---

## television (TUI data browser)

### Configuration

```
dotfiles/dot-config/television/config.toml -> ~/.config/television/config.toml
dotfiles/dot-config/television/cable/ -> ~/.config/television/cable/
dotfiles/dot-config/television/scripts/ -> ~/.config/television/scripts/
```

### Shell Setup

```zsh
# In dot-zshrc
_evalcache tv init zsh
```

### Usage

```bash
tv                      # Default channel (files)
tv git-branch           # Browse git branches
tv brew-packages        # Browse/manage brew packages
tv docker-containers    # Browse containers
tv claude-sessions      # Browse Claude Code sessions
```

### Shell Integration (Ctrl+T)

Type a command, then press `Ctrl+T` — television picks the right channel:

| Command prefix | Channel |
|---------------|---------|
| `git checkout` | git-branch |
| `git add` | git-diff |
| `cd` | dirs |
| `nvim` | files |
| `docker run` | docker-images |

### Key Bindings (inside tv)

| Key | Action |
|-----|--------|
| `Enter` | Confirm selection |
| `Tab` | Multi-select |
| `Ctrl+R` | Remote control (switch channels) |
| `Ctrl+X` | Action picker |
| `Ctrl+Y` | Copy to clipboard |
| `Ctrl+O` | Toggle preview |

### Custom Cable Channels

| Channel | Source | Actions |
|---------|--------|---------|
| brew-packages | brew list | upgrade |
| git-branch | branches | checkout, delete, merge |
| git-log | commit history | — |
| git-diff | changed files | — |
| git-stash | stashes | apply, drop |
| docker-containers | containers | start, logs, exec |
| gh-prs | open PRs | open in browser, checkout |
| k8s-pods | pods | logs, exec |
| claude-sessions | JSONL files | resume, open in VS Code, delete |
| tmux-sessions | sessions | switch |

---

## glow (terminal markdown renderer)

### Configuration

```
dotfiles/dot-config/glow/glow.yml -> ~/.config/glow/glow.yml
```

### Usage

```bash
glow README.md          # Render a markdown file
glow                    # TUI browser for markdown files
cat notes.md | glow     # Pipe markdown into glow
```

### Configuration

| Setting | Value | Purpose |
|---------|-------|---------|
| `style` | auto | Matches terminal dark/light mode |
| `pager` | true | Paginate long documents |
| `width` | 100 | Readable line length |
| `mouse` | true | Scroll in TUI mode |
| `local` | true | No Charm Cloud |

---

## fzf-tab (fuzzy tab completion)

Installed as an oh-my-zsh custom plugin. Replaces default zsh tab completion with fzf.

### Previews (configured via zstyle in dot-zshrc)

| Context | Preview |
|---------|---------|
| `cd` tab | eza directory listing |
| `cat`/`nvim` tab | bat file preview |
| `git checkout` tab | git log graph |
| `kill` tab | process details |
| `brew` tab | brew info |
| `export`/`unset` tab | variable value |

### Key Bindings

| Key | Action |
|-----|--------|
| `Tab` | Trigger fuzzy completion |
| `Ctrl+Space` | Multi-select |
| `<` / `>` | Switch completion groups |
| `/` | Continue into selected directory |
