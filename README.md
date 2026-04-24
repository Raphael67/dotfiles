# 🏠 dotfiles

Cross-platform dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/) — macOS, Arch Linux, and Windows.

![macOS](https://img.shields.io/badge/macOS-000000?style=flat&logo=apple&logoColor=white)
![Arch Linux](https://img.shields.io/badge/Arch_Linux-1793D1?style=flat&logo=archlinux&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-0078D6?style=flat&logo=windows&logoColor=white)

<!-- Add a screenshot of your terminal here -->
<!-- ![Terminal Preview](screenshot.png) -->

## Features

- **Multi-platform** — one repo for macOS, Arch Linux, and Windows
- **GNU Stow** — declarative symlink management with `dot-` prefix convention
- **Catppuccin Macchiato** — consistent theme across 9+ tools
- **Lazy-loaded shell** — fast Zsh startup with deferred nvm/pyenv/jenv loading
- **AI-augmented** — Claude Code skills, hooks, MCP servers, and Copilot integration
- **60+ CLI tools** — curated Brewfile with modern replacements for classic Unix tools
- **Session persistence** — tmux-resurrect + tmux-continuum survive reboots
- **Security** — gitleaks pre-commit hook, Bitwarden CLI, rclone cloud backup

## What's Inside

### Terminal & Shell

| Tool | Description |
|------|-------------|
| [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| [Zsh](https://www.zsh.org) + [Oh-My-Zsh](https://ohmyz.sh) | Shell with plugins (autosuggestions, syntax highlighting) |
| [Starship](https://starship.rs) | Cross-shell prompt |
| [atuin](https://atuin.sh) | Shell history database with fuzzy search |
| [direnv](https://direnv.net) | Per-directory environment variables |
| fzf-tab | Fuzzy tab completion for zsh |
| [Nushell](https://www.nushell.sh) | Structured data shell (secondary) |

### Editor

| Tool | Description |
|------|-------------|
| [Neovim](https://neovim.io) | Primary editor — lazy.nvim, LSP, DAP, Telescope, Treesitter |
| [VSCode](https://code.visualstudio.com) | GUI editor with synced settings |

### Terminal Multiplexer

| Tool | Description |
|------|-------------|
| [tmux](https://github.com/tmux/tmux) | Session management with TPM, resurrect, continuum, fzf integration |

### CLI Replacements

| Classic | Replacement | Description |
|---------|-------------|-------------|
| `ls` | [eza](https://eza.rocks) | Modern ls with icons and git status |
| `cat` | [bat](https://github.com/sharkdp/bat) | Syntax-highlighted cat |
| `cd` | [zoxide](https://github.com/ajeetdsouza/zoxide) | Smarter cd with frecency |
| `find` | [fd](https://github.com/sharkdp/fd) | Simpler, faster find |
| `grep` | [ripgrep](https://github.com/BurntSushi/ripgrep) | Faster grep |
| `top` | [btop](https://github.com/aristocratos/btop) | Resource monitor |
| `git` (TUI) | [lazygit](https://github.com/jesseduffield/lazygit) | Terminal UI for git |
| — | [fzf](https://github.com/junegunn/fzf) | Fuzzy finder for everything |
| `Ctrl+R` | [atuin](https://atuin.sh) | Shell history with fuzzy search, sync, per-directory filtering |
| — | [television](https://github.com/alexpasmantier/television) | TUI data browser (git, docker, brew, sessions) |
| — | [glow](https://github.com/charmbracelet/glow) | Terminal markdown renderer |
| — | [fastfetch](https://github.com/fastfetch-cli/fastfetch) | System info |

### Dev Tools

| Tool | Purpose |
|------|---------|
| Docker | Containers |
| k9s | Kubernetes TUI |
| Postman | API testing |
| nvm / pyenv / jenv / chruby | Version managers (Node, Python, Java, Ruby) |
| rustup | Rust toolchain |
| Go, Lua | Additional languages |
| uv | Python package manager |
| bun | JavaScript runtime & bundler |

### AI Tools

| Tool | Purpose |
|------|---------|
| [Claude Code](https://claude.com/claude-code) | AI coding assistant with custom skills & hooks |

### macOS Extras

| Tool | Purpose |
|------|---------|
| [Karabiner-Elements](https://karabiner-elements.pqrs.org) | Keyboard customization |
| [Hammerspoon](https://www.hammerspoon.org) | macOS automation |
| [AltTab](https://alt-tab-macos.netlify.app) | Windows-style alt-tab |
| [BoringNotch](https://github.com/theboredteam/boring-notch) | Notch utility |
| pam-reattach | Touch ID in tmux |

### Security & Backup

| Tool | Purpose |
|------|---------|
| [Bitwarden CLI](https://bitwarden.com/help/cli/) | Password management |
| [gitleaks](https://github.com/gitleaks/gitleaks) | Pre-commit secret scanning |
| [rclone](https://rclone.org) | Cloud storage sync (installed from the official binary, not brew — FUSE required for `rclone mount`) |

## 🎨 Catppuccin Macchiato

A consistent [Catppuccin Macchiato](https://github.com/catppuccin/catppuccin) theme applied across:

- Ghostty
- Neovim
- tmux
- Starship prompt
- Zsh syntax highlighting
- fzf
- bat
- btop
- lazygit
- atuin
- television
- glow
- VSCode

## Installation

### macOS

```bash
git clone https://github.com/Raphael67/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./setup_macos.sh    # Xcode CLI, Homebrew, Brewfile, oh-my-zsh, stow
```

### Arch Linux / WSL

```bash
git clone https://github.com/Raphael67/dotfiles.git ~/Projects/dotfiles
cd ~/Projects/dotfiles
./setup_archlinux.sh    # pacman packages, oh-my-zsh, zsh plugins
```

### Windows (PowerShell as Admin)

```powershell
.\setup_windows.ps1                   # Full setup
.\setup_windows.ps1 -SkipApps        # Skip Chocolatey packages
.\setup_windows.ps1 -SkipWSL         # Skip WSL configuration
```

After any setup script, apply symlinks:

```bash
stow .
```

## How It Works

This repo uses [GNU Stow](https://www.gnu.org/software/stow/) with a `dot-` prefix convention.

- Source files live in `dotfiles/` — e.g., `dotfiles/dot-zshrc`
- Stow creates symlinks in `~/` — e.g., `~/.zshrc → dotfiles/dot-zshrc`
- The `dot-` prefix is converted to `.` automatically
- Configuration in `.stowrc`:

```
--dir=./dotfiles
--target=~/
--dotfiles
--ignore='\.DS_Store'
```

**Always run `stow .` from the repo root**, never `stow <package>`.

## Shell Performance

Zsh loads fast thanks to lazy loading of version managers:

```
# nvm, pyenv, and jenv are NOT loaded at shell startup.
# They initialize on first use of node/npm/python/java commands.
# This keeps shell startup under ~200ms.
```

## Key Aliases

| Alias | Command | Description |
|-------|---------|-------------|
| `ls` | `eza` | Icons, git status, grouped dirs |
| `cat` | `bat` | Syntax highlighting |
| `lg` | `lazygit` | Git TUI |
| `v` / `vi` | `nvim` | Neovim |
| `g` | `git` | Git shorthand |
| `gs` | `git status` | Status |
| `gc` | `git commit` | Commit |
| `gp` | `git push` | Push |
| `gap` | `git add --patch` | Interactive staging |
| `gqc` | quick commit | Auto-prepends ticket ID from branch |
| `c` | `clear` | Clear terminal |
| `e` | `exit` | Exit shell |

<details>
<summary>More aliases</summary>

| Alias | Command |
|-------|---------|
| `ga` | `git add` |
| `gco` | `git checkout` |
| `gd` | `git diff` |
| `gds` | `git diff --staged` |
| `gl` | `git log --graph` (pretty) |
| `gf` | `git fetch` |
| `gb` | `git branch` |
| `gm` | `git merge` |
| `gup` | `git pull --rebase` |
| `gafzf` | fzf-powered `git add` |
| `gcofzf` | fzf-powered branch checkout |
| `r` | `ranger` |

</details>

## Neovim

Plugin manager: [lazy.nvim](https://github.com/folke/lazy.nvim) — plugins load on demand.

**Highlights:**
- **LSP + blink.cmp** — language servers with ghost text completion, fuzzy matching
- **DAP** — debug adapter protocol
- **Telescope** — fuzzy finder for files, grep, buffers
- **Treesitter** — syntax highlighting and code objects
- **Neo-tree** — file explorer
- **Harpoon** — quick file navigation
- **Aerial** — symbol outline
- **Gitsigns** — inline git blame/hunks
- **Bufferline** — tab-style buffer management
- **Lualine** — statusline
- **vim-tmux-navigator** — seamless tmux/nvim pane switching
- **mini.surround** — add/delete/replace surroundings (quotes, brackets, tags)
- **flash.nvim** — label-based motions and jumps
- **noice.nvim** — floating cmdline, notifications, LSP UI
- **Claude + Copilot** — AI code assistance

## tmux

**Plugins (via TPM):**
- **tmux-resurrect** — save/restore sessions across reboots
- **tmux-continuum** — auto-save every 15 min, auto-restore on start
- **tmux-fzf** — fzf integration for sessions, windows, panes
- **tmux-fzf-url** — open URLs from scrollback with fzf
- **tmux-yank** — clipboard integration
- **tmux-cpu** / **tmux-battery** — status bar widgets
- **tmux-sessionx** — fuzzy session manager with zoxide integration
- **tmux-floax** — floating popup panes
- **vim-tmux-navigator** — seamless Ctrl+h/j/k/l across tmux/nvim
- **catppuccin/tmux** — themed status bar

## Claude AI Integration

This repo includes a full [Claude Code](https://claude.com/claude-code) setup deployed via stow to `~/.claude/`:

- **14+ custom skills** — dotfiles management, document generation (docx, xlsx, pptx, pdf), visual assets, browser automation, prompt engineering, and more
- **Damage control hooks** — safety hooks that review Bash, Edit, and Write tool calls against destructive patterns
- **MCP servers** — Atlassian, Playwright, Context7 (library docs), iCal, and more
- **Custom commands** — context priming, parallel agent orchestration

## Tips

### Ghostty SSH terminfo

Copy Ghostty terminal info to remote servers:

```bash
infocmp -x xterm-ghostty | ssh user@server 'tic -x -'
```

### Karabiner troubleshooting

If Karabiner-Elements stops working after a macOS update, see: [karabiner-elements#3620](https://github.com/pqrs-org/Karabiner-Elements/issues/3620)

## Inspired By

- [omerxx/dotfiles](https://github.com/omerxx/dotfiles)
- [elliottminns/dotfiles](https://github.com/elliottminns/dotfiles)
- [hendrikmi/dotfiles](https://github.com/hendrikmi/dotfiles)
- [obxhdx/dotfiles](https://gitlab.com/obxhdx/dotfiles)

Built with [GNU Stow](https://www.gnu.org/software/stow/), [Catppuccin](https://github.com/catppuccin/catppuccin), [lazy.nvim](https://github.com/folke/lazy.nvim), [TPM](https://github.com/tmux-plugins/tpm), and [Oh-My-Zsh](https://ohmyz.sh/).

---

<p align="center">
  <a href="https://buymeacoffee.com/guilyguily">
    <img src="https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy Me A Coffee" />
  </a>
</p>
