# Tmux Configuration Reference

## File Structure

```
dotfiles/dot-config/tmux/
├── tmux.conf              # Main config (plugin list, sources other files)
├── tmux.reset.conf        # Reset to defaults
├── tmux.catppuccin.conf   # Catppuccin theme configuration
├── tmux.custom.conf       # Custom settings, keybindings
├── scripts/               # Helper scripts
└── plugins/               # TPM plugins directory
    ├── tpm/               # Plugin manager
    ├── tmux-sensible/
    ├── tmux-yank/
    ├── tmux-resurrect/
    ├── tmux-continuum/
    ├── tmux-fzf/
    ├── tmux-fzf-url/
    └── catppuccin/
```

## TPM (Tmux Plugin Manager)

### Installation

```bash
git clone https://github.com/tmux-plugins/tpm ~/.config/tmux/plugins/tpm
```

### Plugin Declaration

```tmux
# In tmux.conf
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-yank'

# Initialize TPM (keep at the very bottom)
run '~/.config/tmux/plugins/tpm/tpm'
```

### Plugin Management Keys

| Key | Action |
|-----|--------|
| `prefix + I` | Install plugins |
| `prefix + U` | Update plugins |
| `prefix + Alt + u` | Remove unlisted plugins |

### Plugin Formats

```tmux
# GitHub shorthand
set -g @plugin 'tmux-plugins/tmux-sensible'

# GitHub with branch
set -g @plugin 'user/plugin#branch'

# Full Git URL
set -g @plugin 'git@github.com:user/plugin'
```

## Current Plugins

| Plugin | Purpose |
|--------|---------|
| `tpm` | Plugin manager |
| `tmux-sensible` | Sensible default settings |
| `tmux-yank` | System clipboard integration |
| `tmux-resurrect` | Save/restore sessions |
| `tmux-continuum` | Auto-save sessions |
| `tmux-fzf` | Fuzzy finder integration |
| `tmux-fzf-url` | Open URLs with fzf |
| `catppuccin/tmux` | Theme |
| `tmux-cpu` | CPU display |
| `tmux-battery` | Battery display |

## Key Bindings

### Prefix Key

```tmux
# Custom prefix (check tmux.custom.conf for actual value)
set -g prefix C-x
unbind C-b
bind C-x send-prefix
```

### Navigation

| Key | Action |
|-----|--------|
| `prefix + h/j/k/l` | Navigate panes (vim-style) |
| `prefix + H/J/K/L` | Resize panes |
| `C-h/j/k/l` | Navigate panes (without prefix, with vim-tmux-navigator) |
| `prefix + n` | Next window |
| `prefix + p` | Previous window |
| `prefix + 0-9` | Go to window by number |

### Panes and Windows

| Key | Action |
|-----|--------|
| `prefix + v` | Split vertical |
| `prefix + %` | Split horizontal |
| `prefix + c` | New window |
| `prefix + x` | Kill pane |
| `prefix + &` | Kill window |
| `prefix + z` | Toggle pane zoom |
| `prefix + {` / `}` | Swap pane |
| `prefix + !` | Break pane to new window |

### Sessions

| Key | Action |
|-----|--------|
| `prefix + d` | Detach |
| `prefix + s` | List sessions |
| `prefix + $` | Rename session |
| `prefix + (` / `)` | Previous/next session |

### Copy Mode

| Key | Action |
|-----|--------|
| `prefix + [` | Enter copy mode |
| `v` | Begin selection (in copy mode) |
| `y` | Copy selection |
| `prefix + ]` | Paste |

### Utility

| Key | Action |
|-----|--------|
| `prefix + r` | Reload config |
| `prefix + :` | Command prompt |
| `prefix + ?` | List key bindings |
| `prefix + N` | Open new Ghostty window without tmux |

## Session Persistence

### tmux-resurrect

Manual save/restore:

| Key | Action |
|-----|--------|
| `prefix + Ctrl + s` | Save session |
| `prefix + Ctrl + r` | Restore session |

### tmux-continuum

Auto-saves every 15 minutes. Configure in tmux.conf:

```tmux
set -g @continuum-restore 'on'      # Auto-restore on tmux start
set -g @continuum-save-interval '15' # Save interval (minutes)
```

## Catppuccin Theme Configuration

```tmux
# In tmux.catppuccin.conf
set -g @catppuccin_flavor 'macchiato'

# Window styling
set -g @catppuccin_window_status_style "rounded"
set -g @catppuccin_window_default_text "#W"
set -g @catppuccin_window_current_text "#W"

# Status bar modules
set -g @catppuccin_status_modules_right "directory session"
set -g @catppuccin_status_modules_left ""

# Pane borders
set -g @catppuccin_pane_active_border_style "fg=#{@thm_lavender}"
```

## Common Configuration Options

### Terminal Settings

```tmux
set -g default-terminal "tmux-256color"
set -ga terminal-features ",*:RGB"
set -g escape-time 10
set -g focus-events on
```

### Window/Pane Options

```tmux
set -g base-index 1          # Start windows at 1
set -g pane-base-index 1     # Start panes at 1
set -g renumber-windows on   # Renumber on close
set -g mouse on              # Enable mouse
set -g history-limit 50000   # Scrollback buffer
```

### Status Bar

```tmux
set -g status on
set -g status-position bottom    # or 'top'
set -g status-interval 1         # Update every second
set -g status-justify left
set -g status-left-length 40
set -g status-right-length 60
```

### Copy Mode

```tmux
setw -g mode-keys vi         # Vi keys in copy mode
```

## Adding a New Plugin

1. Add to `tmux.conf`:
   ```tmux
   set -g @plugin 'author/plugin-name'
   ```

2. Install with `prefix + I`

3. Configure in `tmux.custom.conf`:
   ```tmux
   set -g @plugin-option 'value'
   ```

4. Reload: `prefix + r`

## Custom Key Bindings

Add to `tmux.custom.conf`:

```tmux
# Example: bind prefix + g to lazygit
bind g new-window -c "#{pane_current_path}" "lazygit"

# Split in current directory
bind '"' split-window -v -c "#{pane_current_path}"
bind '%' split-window -h -c "#{pane_current_path}"

# Reload config
bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"
```

## Conditional Configuration

```tmux
# OS-specific settings
%if "#{==:#{host},macbook}"
  set -s copy-command "pbcopy"
%else
  set -s copy-command "xclip -selection clipboard"
%endif
```

## Command Reference

### Session Commands

```bash
# Create session
tmux new -s name

# Attach to session
tmux attach -t name
tmux a -t name

# List sessions
tmux ls

# Kill session
tmux kill-session -t name
```

### Window Commands

```bash
# In tmux command mode (prefix + :)
new-window -n name
rename-window name
kill-window
```

### Pane Commands

```bash
# In tmux command mode
split-window -h     # Horizontal split
split-window -v     # Vertical split
select-pane -t 0    # Select pane
kill-pane
```

## Scripting with tmux

### Send Keys to Pane

```bash
tmux send-keys -t session:window.pane "command" Enter
```

### Create Layout Script

```bash
#!/bin/bash
tmux new-session -d -s dev -n editor
tmux send-keys -t dev:editor "nvim" Enter
tmux new-window -t dev -n terminal
tmux split-window -h -t dev:terminal
tmux attach -t dev
```

## Debugging

### Show Options

```bash
# Show all options
tmux show-options -g

# Show specific option
tmux show-options -g status

# Show window options
tmux show-window-options -g
```

### List Keys

```bash
tmux list-keys
tmux list-keys | grep prefix
```

### Reload and Test

```tmux
# Reload config
prefix + r

# Or from command line
tmux source-file ~/.config/tmux/tmux.conf
```

## Troubleshooting

### Plugins Not Installing

1. Ensure TPM is installed:
   ```bash
   ls ~/.config/tmux/plugins/tpm
   ```

2. Press `prefix + I` inside tmux

3. Check TPM is initialized at bottom of tmux.conf

### Colors Wrong

```tmux
# Ensure true color support
set -g default-terminal "tmux-256color"
set -ga terminal-features ",*:RGB"
```

### Prefix Not Working

1. Check prefix setting:
   ```bash
   tmux show-options -g prefix
   ```

2. Ensure unbind of default:
   ```tmux
   unbind C-b
   ```

### Copy Not Working

For macOS:
```tmux
set -s copy-command "pbcopy"
```

For Linux:
```tmux
set -s copy-command "xclip -selection clipboard"
```

### Session Not Restoring

1. Check resurrect files:
   ```bash
   ls ~/.local/share/tmux/resurrect/
   ```

2. Manually restore:
   ```
   prefix + Ctrl + r
   ```
