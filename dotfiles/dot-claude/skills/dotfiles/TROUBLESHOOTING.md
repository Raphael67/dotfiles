# Troubleshooting Guide

Common issues and solutions for this dotfiles setup.

## Stow Issues

### "existing target is neither a link nor a directory"

**Cause:** A regular file exists at the target location.

**Solution:**
```bash
# Backup and remove the conflicting file
mv ~/.conflicting-file ~/.conflicting-file.bak
stow .
```

### Symlinks Created in Wrong Location

**Cause:** Running `stow <package>` instead of `stow .`

**Solution:**
```bash
# Remove wrong symlinks
stow -D <package>

# Run correctly from project root
cd ~/Projects/dotfiles
stow .
```

### "stow: command not found"

**Solution:**
```bash
# macOS
brew install stow

# Ubuntu/Debian
sudo apt install stow
```

### Verify Symlinks

```bash
# Check specific file
ls -la ~/.zshrc
# Should show: .zshrc -> /Users/raphael/Projects/dotfiles/dotfiles/dot-zshrc

# List all symlinks in home
ls -la ~ | grep "^l"
```

---

## Shell Startup Issues

### Slow Shell Startup

**Diagnosis:**
```bash
zsh-time      # Quick timing
zsh-debug     # Detailed profiling with zprof
```

**Common Causes:**
1. Version managers loading immediately (nvm, pyenv, jenv)
2. Too many plugins
3. Uncached expensive commands

**Solutions:**

1. Verify lazy loading is working:
   ```bash
   # Should NOT see nvm/pyenv in zprof output until first use
   zsh-debug
   ```

2. Check evalcache is being used:
   ```bash
   ls ~/.zsh-evalcache/
   ```

3. Reduce plugins in `dot-zshrc`

### Plugin Errors

**"plugin not found" error:**
```bash
# Check plugin exists
ls $ZSH/plugins/plugin-name
ls $ZSH_CUSTOM/plugins/plugin-name

# Install missing plugin
git clone https://github.com/user/plugin ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/plugin-name
```

### PATH Issues

**Commands not found after install:**
```bash
# Check PATH
echo $PATH | tr ':' '\n'

# Reload shell
source ~/.zshrc

# Or start fresh shell
exec zsh
```

### Aliases Not Working

```bash
# Check alias is defined
alias | grep aliasname

# Reload aliases
source ~/.config/zsh/aliases.zsh

# Or reload entire shell
source ~/.zshrc
```

---

## Tmux Issues

### Plugins Not Loading

**Solution:**
```bash
# 1. Verify TPM is installed
ls ~/.config/tmux/plugins/tpm

# 2. If missing, install:
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm

# 3. Inside tmux, press:
prefix + I   # Install plugins
```

### Colors Wrong in Tmux

**Solution:** Add to tmux.conf:
```tmux
set -g default-terminal "tmux-256color"
set -ga terminal-features ",*:RGB"
```

Then reload:
```bash
tmux source-file ~/.config/tmux/tmux.conf
```

### Prefix Key Not Working

```bash
# Check current prefix
tmux show-options -g prefix

# Common fix: ensure unbind of default
# In tmux.conf:
unbind C-b
set -g prefix C-x
bind C-x send-prefix
```

### Session Not Restoring

```bash
# Check resurrect files exist
ls ~/.local/share/tmux/resurrect/

# Manual restore (inside tmux)
prefix + Ctrl + r

# Check continuum is enabled
# In tmux.conf:
set -g @continuum-restore 'on'
```

### Copy/Paste Not Working

**macOS:**
```tmux
set -s copy-command "pbcopy"
```

**Linux:**
```tmux
set -s copy-command "xclip -selection clipboard"
```

---

## Neovim Issues

### Lazy.nvim Errors

```vim
" Sync plugins
:Lazy sync

" Clear and reinstall
:Lazy clean
:Lazy install

" Check health
:Lazy health
```

### LSP Not Working

```vim
" Check LSP status
:LspInfo

" Check if server is installed
:Mason

" Install missing server
:MasonInstall <server-name>

" Restart LSP
:LspRestart
```

### Treesitter Errors

```vim
" Update all parsers
:TSUpdate

" Reinstall specific parser
:TSInstall <language>

" Check status
:TSModuleInfo

" Health check
:checkhealth vim.treesitter
```

### General Health Check

```vim
:checkhealth
```

This checks all components and shows what's wrong.

### Plugin Not Loading

1. Check plugin file exists in `lua/plugins/`
2. Verify it's required in `init.lua`
3. Check for syntax errors: `:messages`
4. Run `:Lazy sync`

---

## Ghostty Issues

### Terminal Renders Wrong on Remote Servers

**Solution:** Export terminfo to remote:
```bash
infocmp -x | ssh user@host -- tic -x -
```

### Icons/Glyphs Not Displaying

**Solution:** Install Nerd Fonts:
```bash
brew install --cask font-jetbrains-mono-nerd-font
```

Then set in Ghostty config:
```ini
font-family = JetBrains Mono
```

### Shell Integration Not Working

1. Check environment variable:
   ```bash
   echo $GHOSTTY_RESOURCES_DIR
   ```

2. Add manual sourcing to `.zshrc`:
   ```zsh
   if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
       source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty.zsh"
   fi
   ```

### Config Changes Not Applied

Press `Cmd + Shift + ,` (macOS) or `Ctrl + Shift + ,` (Linux) to reload.

Some settings only apply to new terminals.

### Mouse Outputs Escape Sequences Instead of Scrolling/Clicking

**Cause:** Mouse reporting mode got stuck enabled, typically from a program (tmux, vim, less) that crashed or didn't clean up properly.

**Symptoms:**
- Scrolling outputs characters like `[M` or `[<0;`
- Clicking outputs escape sequences instead of positioning cursor
- Mouse wheel doesn't scroll terminal

**Solution:**
```bash
fixmouse   # alias that disables all mouse reporting modes
```

Or manually:
```bash
printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'
```

**If inside tmux**, also try toggling mouse mode:
```bash
tmux set -g mouse off && tmux set -g mouse on
```

---

## Karabiner Issues

### Modifications Not Working

1. **Check permissions:**
   - System Preferences > Security & Privacy > Privacy > Input Monitoring
   - Ensure Karabiner components are allowed

2. **Restart service:**
   ```bash
   launchctl stop org.pqrs.karabiner.karabiner_console_user_server
   launchctl start org.pqrs.karabiner.karabiner_console_user_server
   ```

3. **Check known issues:**
   https://github.com/pqrs-org/Karabiner-Elements/issues/3620

### Configuration Not Loading

```bash
# Verify config exists
cat ~/.config/karabiner/karabiner.json | head

# Check for JSON syntax errors
cat ~/.config/karabiner/karabiner.json | jq .
```

---

## Theme Consistency Issues

### Colors Look Different Across Apps

**Check each app's theme setting:**

| App | Config Location | Theme Setting |
|-----|-----------------|---------------|
| Neovim | `lua/plugins/` | `colorscheme("catppuccin")` |
| Tmux | `tmux.catppuccin.conf` | `@catppuccin_flavor 'macchiato'` |
| Starship | `starship.toml` | `palette = "catppuccin_macchiato"` |
| Ghostty | `config` | `theme = catppuccin-mocha` |
| fzf | `dot-zshrc` | `FZF_DEFAULT_OPTS` colors |

### Nerd Font Icons Missing

**Verify font installation:**
```bash
# List installed fonts (macOS)
fc-list | grep -i nerd

# If missing:
brew install --cask font-jetbrains-mono-nerd-font
```

**Check terminal is using the font:**
- Ghostty: `font-family = JetBrains Mono`
- iTerm2: Preferences > Profiles > Text > Font

---

## Homebrew Issues

### Brewfile Install Fails

```bash
# Update Homebrew first
brew update

# Check for issues
brew doctor

# Try installing again
brew bundle --file=homebrew/Brewfile
```

### Package Not Found

```bash
# Search for correct name
brew search package-name

# Check if it's a cask
brew search --cask package-name
```

---

## Git/GPG Issues

### GPG Signing Fails

```bash
# Check GPG agent
gpg-connect-agent /bye

# Restart agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Verify key
gpg --list-secret-keys --keyid-format=long
```

### Commit Signing Not Working

```bash
# Check Git config
git config --global user.signingkey
git config --global commit.gpgsign

# Test signing
echo "test" | gpg --clearsign
```

---

## General Debugging

### Check What's Loaded

```bash
# Shell functions
functions | head -20

# Environment variables
env | sort

# Aliases
alias
```

### Fresh Shell Without Config

```bash
# Start shell without loading config
zsh -f

# Or with NO_TMUX to avoid tmux
NO_TMUX=1 zsh
```

### Check File Permissions

```bash
# Dotfiles should be readable
ls -la ~/.zshrc
# Should show: -rw-r--r-- or lrwxr-xr-x (symlink)

# Scripts should be executable
ls -la ~/.local/bin/
```

### Verify Symlinks Point to Right Place

```bash
# Check a symlink
readlink ~/.zshrc
# Should show: /Users/raphael/Projects/dotfiles/dotfiles/dot-zshrc

# Follow all symlinks
readlink -f ~/.zshrc
```
