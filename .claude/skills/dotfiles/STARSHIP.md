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

## Format String Syntax

Starship format strings use three core elements:

| Element | Syntax | Example |
|---------|--------|---------|
| Variable | `$variable_name` | `$directory`, `$git_branch` |
| Text Group | `[text]($style)` | `[  $branch](bold green)` |
| Conditional | `(content)` | `($git_status)` — only renders when variables have values |

**Escape characters:** `$`, `[`, `]`, `(`, `)` must be escaped with `\` to display literally.

### Disabled-by-Default Modules

These modules must be explicitly enabled in your config:
- Azure, CPP, Direnv, Fossil Branch, Fossil Metrics, Git Metrics, Kubernetes

## Current Prompt Format

```toml
format = """
$hostname\
$directory\
$git_branch\
$git_status\
$fill\
$python\
$lua\
$nodejs\
$golang\
$haskell\
$rust\
$ruby\
$aws\
$docker_context\
$jobs\
$cmd_duration\
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

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"
```

## Module Configuration Examples

### Directory

```toml
[directory]
style = "fg:#e3e5e5 bg:#769ff0"
format = "[ $path ]($style)"
truncation_length = 0
truncate_to_repo = false
truncation_symbol = "…/"

[directory.substitutions]
"Documents" = "󰈙 "
"Downloads" = " "
"Music" = " "
"Pictures" = " "
```

### Git Branch

```toml
[git_branch]
symbol = ""
style = "bg:#394260"
format = '[[ $symbol $branch ](fg:#769ff0 bg:#394260)]($style)'
```

### Git Status

```toml
[git_status]
style = "bg:#394260"
format = '[[($all_status$ahead_behind )](fg:#769ff0 bg:#394260)]($style)'
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
min_time = 500
style = 'fg:gray'
format = '[$duration]($style)'
```

### Language Modules

```toml
[python]
style = "bg:#212736"
symbol = ' '
format = '[${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'
pyenv_version_name = true
pyenv_prefix = ''

[nodejs]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[rust]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[golang]
symbol = ""
style = "bg:#212736"
format = '[[ $symbol ($version) ](fg:#769ff0 bg:#212736)]($style)'

[lua]
format = '[$symbol($version )]($style)'
symbol = ' '

[haskell]
style = 'blue'
symbol = ' '

[ruby]
style = 'blue'
symbol = ' '
```

### AWS

```toml
[aws]
symbol = ' '
style = 'yellow'
format = '[$symbol($profile )(\[$duration\] )]($style)'
```

### Docker Context

```toml
[docker_context]
symbol = ' '
style = 'fg:#06969A'
format = '[$symbol]($style) $path'
detect_files = ['docker-compose.yml', 'docker-compose.yaml', 'Dockerfile']
detect_extensions = ['Dockerfile']
```

### Jobs

```toml
[jobs]
symbol = ' '
style = 'red'
number_threshold = 1
format = '[$symbol]($style)'
```

### Package

```toml
[package]
symbol = '󰏗 '
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
ssh_only = false
style = "fg:#cad3f5 bg:#494d64"
format = "[ $hostname ]($style)"
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
