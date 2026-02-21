# Starship Prompt Configuration Reference

## Configuration Location

```
dotfiles/dot-config/starship/starship.toml -> ~/.config/starship/starship.toml
```

Environment variable (set in `dot-zshrc`):
```zsh
export STARSHIP_CONFIG=~/.config/starship/starship.toml
```

## Initialization

```zsh
# In dot-zshrc (cached for faster startup)
_evalcache starship init zsh
```

## Configuration Syntax

```toml
# Root-level options
format = "..."              # Overall prompt layout
right_format = "..."        # Right-aligned elements
add_newline = true          # Blank line before prompt
palette = "name"            # Active color palette

# Module configuration
[module_name]
format = "..."
symbol = "..."
style = "..."
disabled = false
```

## Current Prompt Format

```toml
format = """
$hostname\
$directory\
$git_branch\
$git_status\
$fill\
$docker_context\
$python\
$nodejs\
$rust\
$golang\
$php\
$lua\
$haskell\
$ruby\
$cmd_duration\
$jobs\
$line_break\
$character"""
```

## Catppuccin Macchiato Palette

```toml
palette = "catppuccin_macchiato"

[palettes.catppuccin_macchiato]
rosewater = "#f4dbd6"
flamingo = "#f0c6c6"
pink = "#f5bde6"
mauve = "#c6a0f6"
red = "#ed8796"
maroon = "#ee99a0"
peach = "#f5a97f"
yellow = "#eed49f"
green = "#a6da95"
teal = "#8bd5ca"
sky = "#91d7e3"
sapphire = "#7dc4e4"
blue = "#8aadf4"
lavender = "#b7bdf8"
text = "#cad3f5"
subtext1 = "#b8c0e0"
subtext0 = "#a5adcb"
overlay2 = "#939ab7"
overlay1 = "#8087a2"
overlay0 = "#6e738d"
surface2 = "#5b6078"
surface1 = "#494d64"
surface0 = "#363a4f"
base = "#24273a"
mantle = "#1e2030"
crust = "#181926"
```

## Module Configuration Examples

### Directory

```toml
[directory]
style = "fg:text bg:surface0"
format = "[ $path ]($style)"
truncation_length = 3
truncate_to_repo = false

[directory.substitutions]
"Documents" = "docs"
"Downloads" = "down"
"~/Projects" = "proj"
```

### Git Branch

```toml
[git_branch]
symbol = ""
style = "fg:mauve"
format = '[$symbol $branch ]($style)'
truncation_length = 20
```

### Git Status

```toml
[git_status]
style = "fg:red"
format = '([$all_status$ahead_behind]($style) )'
conflicted = "="
ahead = "⇡${count}"
behind = "⇣${count}"
diverged = "⇕⇡${ahead_count}⇣${behind_count}"
untracked = "?"
stashed = "\\$"
modified = "!"
staged = "+"
renamed = "»"
deleted = "✘"
```

### Character (Prompt Symbol)

```toml
[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"
```

### Command Duration

```toml
[cmd_duration]
min_time = 2000                    # Show if > 2 seconds
format = "[$duration]($style) "
style = "fg:yellow"
```

### Language Modules

```toml
[python]
symbol = ""
style = "bg:surface0"
format = '[[ $symbol ($version) (\($virtualenv\)) ](fg:blue bg:surface0)]($style)'
pyenv_version_name = true

[nodejs]
symbol = ""
style = "bg:surface0"
format = '[[ $symbol ($version) ](fg:green bg:surface0)]($style)'

[rust]
symbol = ""
style = "bg:surface0"
format = '[[ $symbol ($version) ](fg:peach bg:surface0)]($style)'

[golang]
symbol = ""
style = "bg:surface0"
format = '[[ $symbol ($version) ](fg:sky bg:surface0)]($style)'
```

### Docker Context

```toml
[docker_context]
symbol = ""
style = "bg:surface0"
format = '[[ $symbol $context ](fg:sky bg:surface0)]($style)'
only_with_files = true
detect_files = ["docker-compose.yml", "Dockerfile"]
```

## Adding a New Language Module

1. Find the module name in [Starship docs](https://starship.rs/config/)

2. Add configuration:
   ```toml
   [newlang]
   symbol = "icon"
   style = "bg:surface0"
   format = '[[ $symbol ($version) ](fg:color bg:surface0)]($style)'
   ```

3. Add to format string:
   ```toml
   format = """
   ...\
   $newlang\
   ..."""
   ```

4. Reload shell: `source ~/.zshrc`

## Conditional Visibility

### Detect by Files/Extensions

```toml
[python]
detect_extensions = ["py"]
detect_files = ["requirements.txt", "pyproject.toml", ".python-version"]
detect_folders = [".venv", "venv"]
```

### Negative Matching

```toml
detect_extensions = ['ts', '!video.ts', '!audio.ts']
```

### Conditional Groups

```toml
# Only shows if $region has a value
format = '(@$region)'
```

## Style Syntax

```toml
# Named colors
style = "bold green"
style = "fg:green bg:blue"

# Catppuccin palette colors
style = "fg:mauve bg:surface0"

# Hex colors
style = "fg:#8aadf4"

# 256 colors
style = "fg:27 bold"

# Effects
# bold, italic, underline, dimmed, inverted, blink, strikethrough
style = "bold italic fg:blue"
```

## Special Modules

### Fill (Spacer)

```toml
[fill]
symbol = " "
```

Creates space between left and right elements.

### Line Break

```toml
[line_break]
disabled = false
```

### Hostname

```toml
[hostname]
ssh_only = true
format = "[$hostname]($style) "
style = "fg:green"
```

### Username

```toml
[username]
show_always = false
format = "[$user]($style) "
style = "fg:blue"
```

### Time

```toml
[time]
disabled = false
time_format = "%H:%M"
format = "[$time]($style) "
style = "fg:subtext0"
```

## Performance Considerations

### Timeout Settings

```toml
# Root-level
scan_timeout = 30       # File scanning (ms)
command_timeout = 500   # External commands (ms)
```

### Disable Unused Modules

```toml
[aws]
disabled = true

[gcloud]
disabled = true
```

### Reduce Scans

```toml
[directory]
truncate_to_repo = true  # Less path computation
```

## Common Customizations

### Two-Line Prompt

```toml
format = """
$directory$git_branch$git_status
$character"""
```

### Right Prompt

```toml
right_format = "$time"
```

### Minimal Prompt

```toml
format = "$directory$character"
```

### Show Git Only in Repos

```toml
[git_branch]
# Only shows when in a git repo (default behavior)
```

## Debugging

### Check Configuration

```bash
starship config
```

### Explain Current Prompt

```bash
starship explain
```

### Timing Information

```bash
starship timings
```

### Print Specific Module

```bash
starship module git_status
```

## Presets

Starship includes built-in presets:

```bash
# List available presets
starship preset --list

# Apply a preset (overwrites config!)
starship preset nerd-font-symbols -o ~/.config/starship.toml
```

**Available presets:**
- nerd-font-symbols
- no-nerd-font
- bracketed-segments
- plain-text-symbols
- no-runtime-versions
- pastel-powerline
- tokyo-night
- gruvbox-rainbow

## Troubleshooting

### Prompt Not Showing

1. Check initialization in `.zshrc`:
   ```zsh
   eval "$(starship init zsh)"
   ```

2. Verify config path:
   ```bash
   echo $STARSHIP_CONFIG
   ```

### Icons Not Displaying

Install Nerd Fonts:
```bash
brew install --cask font-jetbrains-mono-nerd-font
```

### Slow Prompt

1. Check timings: `starship timings`
2. Increase timeouts or disable slow modules
3. Use `truncate_to_repo = true` for directory

### Git Status Slow

For large repos:
```toml
[git_status]
disabled = true  # Or just hide specific indicators
```

Or in shell:
```bash
export STARSHIP_GIT_SCAN_TIMEOUT=100
```

## Nushell Integration

Starship integrates with Nushell via the **vendor autoload** mechanism:

```
$nu.vendor-autoload-dirs → loads starship init automatically
```

No manual prompt configuration needed — starship is loaded by the vendor autoload directory when Nushell starts.

### Manual Alternative

If not using vendor autoload:

```nushell
$env.STARSHIP_SHELL = "nu"
def create_left_prompt [] { starship prompt --cmd-duration $env.CMD_DURATION_MS }
$env.PROMPT_COMMAND = { || create_left_prompt }
```
