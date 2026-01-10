---
name: dotfiles
description: Expert in managing dotfiles using GNU Stow. Use when working with shell configs (zsh, oh-my-zsh, bash), editors (neovim, nvim, vscode), terminal tools (tmux, ghostty), prompts (starship), CLI replacements (eza, bat, fzf, zoxide, lazygit), keyboard (karabiner), secrets (bitwarden-cli), or any configuration in ~/.config. Covers stow symlink management, lazy loading patterns, Catppuccin theming, security best practices, and this specific dotfiles repository structure.
user-invocable: false
---

# Dotfiles Management Skill

Expert guidance for managing this cross-platform dotfiles repository using GNU Stow.

## Quick Reference

| Topic | File | Use When |
|-------|------|----------|
| Zsh/Shell | [ZSH.md](ZSH.md) | Editing .zshrc, aliases, plugins, Oh-My-Zsh |
| Neovim | [NEOVIM.md](NEOVIM.md) | Editing nvim config, adding plugins, LSP |
| Starship | [STARSHIP.md](STARSHIP.md) | Customizing prompt, modules, palettes |
| Tmux | [TMUX.md](TMUX.md) | Editing tmux config, plugins, keybindings |
| Ghostty | [GHOSTTY.md](GHOSTTY.md) | Terminal config, shell integration, keybindings |
| GNU Stow | [STOW.md](STOW.md) | Understanding symlinks, stow commands |
| CLI Tools | [TOOLS.md](TOOLS.md) | Configuring bat, eza, fzf, zoxide, lazygit, bitwarden |
| Problems | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Fixing common issues |

## Critical Repository Pattern

<critical>
**ALWAYS run `stow .` from project root, NEVER `stow <package-name>`.**

The `.stowrc` file configures:
- `--dir=./dotfiles` - stow source directory
- `--target=~/` - symlinks created in home
- `--dotfiles` - `dot-` prefix converts to `.`

Example: `dot-zshrc` becomes `~/.zshrc`
</critical>

## Directory Structure

```
/Users/raphael/Projects/dotfiles/
├── .stowrc                    # Stow configuration
├── CLAUDE.md                  # Claude Code project instructions
├── setup.sh                   # Main installation script
├── homebrew/
│   └── Brewfile               # Package manifest
├── dotfiles/                  # Stow source directory
│   ├── dot-zshrc              # -> ~/.zshrc
│   ├── dot-zprofile           # -> ~/.zprofile
│   ├── dot-config/            # -> ~/.config/
│   │   ├── nvim/              # Neovim (lazy.nvim)
│   │   ├── tmux/              # Tmux + TPM
│   │   ├── starship/          # Starship prompt
│   │   ├── ghostty/           # Ghostty terminal
│   │   ├── zsh/               # Zsh aliases
│   │   ├── bat/               # bat config
│   │   ├── lazygit/           # lazygit config
│   │   ├── karabiner/         # Keyboard mods
│   │   └── nushell/           # Nushell config
│   ├── dot-claude/            # -> ~/.claude/
│   │   ├── settings.json      # Claude Code settings
│   │   ├── statusline.sh      # Token usage tracker
│   │   ├── hooks/             # PreToolUse hooks
│   │   └── skills/            # Claude Code skills
│   └── dot-local/
│       └── bin/               # Utility scripts
└── scripts/                   # Installation helpers
```

## Essential Commands

```bash
# Apply configuration changes
stow .                           # Create/update symlinks
stow -R .                        # Force restow (unlink + relink)
stow -D .                        # Remove all symlinks
stow -n .                        # Dry run (show what would happen)

# Reload configurations
source ~/.zshrc                  # Shell changes
tmux source-file ~/.config/tmux/tmux.conf  # Tmux changes

# Neovim
:Lazy sync                       # Update plugins
:Mason                           # Manage LSP servers
:checkhealth                     # Diagnose issues

# Tmux plugins (TPM)
prefix + I                       # Install plugins
prefix + U                       # Update plugins

# Package management
brew bundle --file=homebrew/Brewfile  # Install all packages
```

## Theme Consistency

<theme>
**Catppuccin Macchiato** is used consistently across all tools:

| Tool | Config Location | Theme Setting |
|------|-----------------|---------------|
| Neovim | `lua/plugins/` | `catppuccin-macchiato` |
| Tmux | `tmux.catppuccin.conf` | `macchiato` |
| Starship | `starship.toml` | `catppuccin_macchiato` palette |
| Ghostty | `config` | `theme = catppuccin-mocha` |
| fzf | `dot-zshrc` | Catppuccin colors in FZF_DEFAULT_OPTS |
| bat | `bat/config` | OneHalfDark |
| lazygit | `lazygit/config.yml` | Catppuccin |

**Key Colors (Macchiato):**
- Base: `#24273a`
- Text: `#cad3f5`
- Blue: `#8aadf4`
- Green: `#a6da95`
- Red: `#ed8796`
</theme>

## Performance Patterns

<performance>
### Lazy Loading for Version Managers

Version managers (jenv, pyenv, nvm) are lazy-loaded to speed up shell startup:

```zsh
# Pattern used in dot-zshrc
if [[ -d "$HOME/.jenv" ]]; then
  jenv() {
    unset -f jenv
    export PATH="$HOME/.jenv/bin:$PATH"
    _evalcache jenv init -
    jenv "$@"
  }
fi
```

### evalcache Plugin

Expensive command outputs are cached using the `evalcache` oh-my-zsh plugin:
```zsh
_evalcache zoxide init zsh --cmd cd
_evalcache gh copilot alias -- zsh
```

### Benchmarking

```bash
zsh-time      # Quick timing: time zsh -i -c exit
zsh-debug     # Detailed profiling with zprof
```
</performance>

## Security Best Practices

<security>
### Never Commit Secrets

These should NEVER be in the repository:
- Passwords and API keys
- SSH keys (~/.ssh/)
- GPG keys (~/.gnupg/)
- Session tokens

### Environment Variables

Load secrets from secure sources:
```zsh
# In dot-zshrc - loads ~/.env if it exists
if [[ -f ~/.env ]]; then
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            export "$line"
        fi
    done < ~/.env
fi
```

### Bitwarden CLI Integration

Use Bitwarden CLI for secure secret access:
```bash
bw-unlock              # Unlock vault, export BW_SESSION
bwp "GitHub Token"     # Get password by name
bwc "API Key"          # Copy to clipboard
```

See [TOOLS.md](TOOLS.md) for full Bitwarden CLI setup.

### File Permissions

Sensitive files should have restricted permissions:
```bash
chmod 400 ~/.ssh/id_*
chmod 600 ~/.env
```
</security>

## File Modification Workflow

<workflow>
1. **Edit files in `dotfiles/dot-*`** (NOT directly in home directory)
   ```bash
   nvim dotfiles/dot-config/zsh/aliases.zsh
   ```

2. **Apply changes with stow**
   ```bash
   stow .
   ```

3. **Reload the relevant configuration**
   ```bash
   source ~/.zshrc                    # For shell changes
   tmux source ~/.config/tmux/tmux.conf  # For tmux
   # Neovim auto-reloads on file save
   ```

4. **Test the changes**

5. **Commit when satisfied**
   ```bash
   git add -A && git commit -m "feat: description"
   ```
</workflow>

## Adding New Configurations

### Adding a New Dotfile

1. Create the file with `dot-` prefix:
   ```bash
   # For ~/.newconfig
   touch dotfiles/dot-newconfig

   # For ~/.config/app/config
   mkdir -p dotfiles/dot-config/app
   touch dotfiles/dot-config/app/config
   ```

2. Run `stow .` to create symlinks

3. Verify with `ls -la ~/ | grep newconfig`

### Adding to Brewfile

```bash
# Add formula
echo 'brew "package-name"' >> homebrew/Brewfile

# Add cask
echo 'cask "app-name"' >> homebrew/Brewfile

# Install
brew bundle --file=homebrew/Brewfile
```

## Cross-Platform Notes

<platform>
### macOS vs Linux

The repository supports both platforms with conditional logic:

```zsh
# In dot-zshrc
if [[ -d /opt/homebrew/bin ]]; then
  export PATH=/opt/homebrew/bin:$PATH
fi
```

### Platform-Specific Paths

| Item | macOS | Linux |
|------|-------|-------|
| Homebrew | `/opt/homebrew/` | `/home/linuxbrew/` |
| VSCode settings | `~/Library/Application Support/Code/` | `~/.config/Code/` |
| Ghostty config | Both use `~/.config/ghostty/` | Same |
</platform>

## When to Read Reference Files

**Read ZSH.md when:**
- Adding shell aliases or functions
- Configuring Oh-My-Zsh plugins
- Troubleshooting shell startup

**Read NEOVIM.md when:**
- Adding or configuring plugins
- Setting up LSP for a language
- Customizing keymaps

**Read TMUX.md when:**
- Modifying keybindings
- Adding or updating plugins
- Configuring status bar

**Read GHOSTTY.md when:**
- Changing terminal appearance
- Setting up shell integration
- Customizing keybindings

**Read STOW.md when:**
- Understanding how symlinks work
- Resolving stow conflicts
- Adding new configuration packages

**Read TOOLS.md when:**
- Configuring CLI tool replacements
- Setting up Bitwarden CLI
- Customizing fzf, bat, eza, etc.

**Read TROUBLESHOOTING.md when:**
- Shell startup is slow
- Plugins aren't loading
- Symlinks aren't working
- Theme colors are wrong
