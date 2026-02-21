# Ghostty Terminal Configuration Reference

## Configuration Location

```
dotfiles/dot-config/ghostty/config -> ~/.config/ghostty/config
```

macOS alternative: `~/Library/Application Support/com.mitchellh.ghostty/config`

## Configuration Syntax

```ini
# Comments must be on their own line
key = value
key = "quoted value"

# Empty value resets to default
font-family =

# Include other configs
config-file = themes/extra.conf
config-file = ?optional/config    # ? prefix makes it optional
```

**Rules:**
- Keys are case-sensitive (use lowercase)
- One setting per line
- No inline comments

## Runtime Reloading

| Platform | Shortcut |
|----------|----------|
| macOS | `Cmd + Shift + ,` |
| Linux | `Ctrl + Shift + ,` |

Some options only apply to new terminals.

## Font Configuration

```ini
font-family = JetBrains Mono
font-size = 14
font-style = regular
font-style-bold = bold
font-style-italic = italic

# Enable ligatures
font-feature = calt
font-feature = liga

# Variable font axes (if supported)
font-variation = wght 400
```

## Theme and Colors

```ini
# Use built-in theme (Ghostty 1.2.0+ uses Title Case)
theme = Catppuccin Macchiato

# Or customize directly
background = 24273a
foreground = cad3f5

# Cursor
cursor-color = f4dbd6
cursor-text = 24273a

# Selection
selection-foreground = cad3f5
selection-background = 494d64

# 256-color palette override
palette = 0=#494d64
palette = 1=#ed8796
palette = 2=#a6da95
# ... etc
```

**Available Catppuccin themes (Ghostty 1.2.0+, Title Case):**
- `Catppuccin Mocha` (darkest)
- `Catppuccin Macchiato`
- `Catppuccin Frappe`
- `Catppuccin Latte` (light)

> **Note:** Ghostty 1.2.0+ switched from kebab-case (`catppuccin-mocha`) to Title Case (`Catppuccin Macchiato`). Update configs accordingly.

### Auto Light/Dark Switching

Ghostty can switch themes based on system appearance:

```ini
# Automatic theme switching
theme = light:Catppuccin Latte,dark:Catppuccin Macchiato
```

## Window Settings

```ini
# Initial size (grid cells)
window-width = 120
window-height = 40

# Padding (pixels)
window-padding-x = 8
window-padding-y = 8

# Window decoration
window-decoration = auto    # none, auto, client, server

# Fullscreen
fullscreen = false
maximize = false
```

## macOS-Specific Settings

```ini
# Titlebar style
macos-titlebar-style = transparent    # native, transparent, tabs

# Option key as Alt (for terminal apps)
macos-option-as-alt = true    # false, left, right, true

# App icon variant
macos-icon = default    # official, blueprint, xray, etc.

# Secure keyboard entry indicator
macos-secure-input-indication = true
```

## Shell Integration

### Supported Shells

| Shell | Auto-Injection |
|-------|----------------|
| bash | Yes |
| zsh | Yes |
| fish | Yes |
| elvish | Yes |
| nushell | Built-in support |

### Configuration

```ini
# Auto-detect (default)
shell-integration = detect

# Force specific shell
shell-integration = zsh

# Disable
shell-integration = none
```

### Manual Setup (if needed)

**Zsh** (`~/.zshrc`):
```zsh
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty.zsh"
fi
```

**Bash** (`~/.bashrc`):
```bash
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/bash/ghostty.bash"
fi
```

### Nushell Integration

```ini
# In Ghostty config — use Nushell as shell
command = /opt/homebrew/bin/nu

# Shell integration works automatically with Nushell
shell-integration = detect
```

Nushell has built-in Ghostty shell integration — no manual sourcing needed.

### Features Enabled

- Prompt awareness (no close confirmation at prompt)
- Directory persistence (new terminals open in current dir)
- Smart prompt resize
- Command output selection (`Ctrl/Cmd + click`)
- Prompt navigation in scrollback
- `Alt + click` cursor positioning

## Keybinding Customization

### Syntax

```ini
keybind = trigger=action
```

### Modifiers

| Modifier | Aliases |
|----------|---------|
| `shift` | - |
| `ctrl` | `control` |
| `alt` | `opt`, `option` |
| `super` | `cmd`, `command` |

### Common Keybindings

```ini
# Clipboard
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard

# Splits
keybind = ctrl+d=new_split:right
keybind = ctrl+shift+d=new_split:down
keybind = ctrl+w=close_surface

# Split navigation
keybind = ctrl+shift+left=goto_split:left
keybind = ctrl+shift+right=goto_split:right
keybind = ctrl+shift+up=goto_split:up
keybind = ctrl+shift+down=goto_split:down

# Tabs
keybind = ctrl+shift+t=new_tab
keybind = ctrl+tab=next_tab
keybind = ctrl+shift+tab=previous_tab
keybind = ctrl+1=goto_tab:1
keybind = ctrl+2=goto_tab:2

# Font size
keybind = ctrl+plus=increase_font_size:1
keybind = ctrl+minus=decrease_font_size:1
keybind = ctrl+0=reset_font_size

# Scrolling
keybind = shift+pageup=scroll_page_up
keybind = shift+pagedown=scroll_page_down

# Prompt navigation (requires shell integration)
keybind = ctrl+shift+z=jump_to_prompt:-1
keybind = ctrl+shift+x=jump_to_prompt:1
```

### Unbind Keys

```ini
keybind = ctrl+q=unbind
keybind = ctrl+w=ignore    # Consume but do nothing
```

### Send Text/Escape Sequences

```ini
# Send text (Zig string syntax)
keybind = ctrl+u=text:\x15

# Send CSI sequence
keybind = ctrl+up=csi:A

# Send escape sequence
keybind = alt+d=esc:d
```

## Terminal Behavior

```ini
# Shell command
command = /bin/zsh

# Initial command (first terminal only)
initial-command = tmux new-session -A -s main

# Scrollback buffer (bytes)
scrollback-limit = 10000000

# Clipboard access
clipboard-read = ask      # ask, allow, deny
clipboard-write = allow

# Mouse behavior
mouse-hide-while-typing = true
focus-follows-mouse = false
```

## Splits and Tabs

### Creating Splits

| Action | Default Key |
|--------|-------------|
| Split right | `Ctrl + d` |
| Split down | `Ctrl + Shift + d` |
| Close split | `Ctrl + w` |

### Navigating Splits

| Action | Default Key |
|--------|-------------|
| Go left | `Ctrl + Shift + Left` |
| Go right | `Ctrl + Shift + Right` |
| Go up | `Ctrl + Shift + Up` |
| Go down | `Ctrl + Shift + Down` |

### Resizing Splits

```ini
keybind = ctrl+alt+left=resize_split:left,10
keybind = ctrl+alt+right=resize_split:right,10
keybind = ctrl+alt+up=resize_split:up,10
keybind = ctrl+alt+down=resize_split:down,10

# Equalize all splits
keybind = ctrl+shift+e=equalize_splits
```

## Linux/GTK Settings

```ini
# Single instance (better performance)
gtk-single-instance = true

# Tab location
gtk-tabs-location = top    # top, bottom, left, right, hidden

# Custom CSS
gtk-custom-css = /path/to/custom.css
```

## CLI Options

```bash
# Start with specific config
ghostty --config-file=/path/to/config

# Override settings
ghostty --background=282c34 --font-family="JetBrains Mono"

# Show all config options with descriptions
ghostty +show-config --default --docs
```

## Remote Server Setup

When Ghostty renders incorrectly on remote servers, export terminfo:

```bash
infocmp -x | ssh user@host -- tic -x -
```

This installs Ghostty's terminfo on the remote server.

## Tiling Window Manager Integration

### Aerospace (macOS)

```toml
# ~/.config/aerospace/aerospace.toml
[[on-window-detected]]
if.app-id = "com.mitchellh.ghostty"
run = ["layout tiling"]
```

### Yabai (macOS)

```bash
yabai -m signal --add app='^Ghostty$' event=window_created action='yabai -m space --layout bsp'
yabai -m signal --add app='^Ghostty$' event=window_destroyed action='yabai -m space --layout bsp'
```

## Example Complete Configuration

```ini
# ~/.config/ghostty/config

# Font
font-family = JetBrains Mono
font-size = 14
font-feature = calt
font-feature = liga

# Theme
theme = Catppuccin Macchiato

# Window
window-padding-x = 8
window-padding-y = 8
window-decoration = auto

# Terminal
scrollback-limit = 10000000
shell-integration = detect
clipboard-read = ask
clipboard-write = allow

# macOS
macos-titlebar-style = transparent
macos-option-as-alt = true

# Keybindings
keybind = ctrl+shift+c=copy_to_clipboard
keybind = ctrl+shift+v=paste_from_clipboard
keybind = ctrl+d=new_split:right
keybind = ctrl+shift+d=new_split:down
keybind = ctrl+w=close_surface
```

## Troubleshooting

### Icons/Glyphs Not Showing

Install Nerd Fonts:
```bash
brew install --cask font-jetbrains-mono-nerd-font
```

### Colors Look Wrong

1. Verify theme name is correct
2. Check `TERM` environment variable
3. Try explicit colors instead of theme

### Shell Integration Not Working

1. Check if `GHOSTTY_RESOURCES_DIR` is set
2. Add manual sourcing to shell config
3. Verify shell-integration setting

### Keybindings Not Working

1. Check for conflicts with system shortcuts
2. Verify modifier key names
3. Use `unbind` to clear defaults first

### Slow Performance

1. Enable `gtk-single-instance = true` on Linux
2. Reduce scrollback-limit
3. Check font rendering settings
