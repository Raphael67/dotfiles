# GNU Stow Reference

## Core Concepts

### Terminology

| Term | Definition |
|------|------------|
| **Stow Directory** | Source directory containing packages (default: current directory) |
| **Target Directory** | Where symlinks are created (default: parent of stow directory) |
| **Package** | A subdirectory in the stow directory |
| **Installation Image** | The file/directory layout within a package |

### How Stow Works

Stow creates symlinks from the target directory to files in the stow directory, mirroring the package structure.

```
# Package structure
dotfiles/
└── zsh/
    └── .zshrc

# After stow
~/.zshrc -> ~/dotfiles/zsh/.zshrc
```

## This Repository's Configuration

### .stowrc File

```
--dir=./dotfiles
--target=~/
--dotfiles
--ignore='\.DS_Store'
```

| Option | Effect |
|--------|--------|
| `--dir=./dotfiles` | Stow directory is `./dotfiles/` |
| `--target=~/` | Symlinks go to home directory |
| `--dotfiles` | `dot-` prefix converts to `.` |
| `--ignore` | Patterns to skip |

### The --dotfiles Flag

Converts `dot-` prefix to `.`:

| Package Path | Symlink Created |
|--------------|-----------------|
| `dot-zshrc` | `~/.zshrc` |
| `dot-config/nvim/` | `~/.config/nvim/` |
| `dot-claude/` | `~/.claude/` |
| `dot-local/bin/` | `~/.local/bin/` |

## Critical Usage Pattern

<critical>
**ALWAYS run `stow .` from the project root.**

**NEVER run `stow <package-name>`.**

Why? Running `stow dot-claude` directly:
- Ignores `.stowrc` settings
- Creates wrong symlinks (e.g., `~/dot-claude/` instead of `~/.claude/`)

The `.stowrc` file only takes effect when running `stow .`
</critical>

## Common Commands

### Basic Operations

```bash
# Apply all configurations (from project root)
stow .

# Force restow (unlink then relink)
stow -R .

# Remove all symlinks
stow -D .

# Dry run (show what would happen)
stow -n .

# Verbose output
stow -v .

# Very verbose
stow -vv .
```

### Command Options

| Flag | Long Form | Description |
|------|-----------|-------------|
| `-S` | `--stow` | Stow packages (default) |
| `-D` | `--delete` | Unstow packages |
| `-R` | `--restow` | Restow (unstow then stow) |
| `-n` | `--simulate` | Dry run |
| `-v` | `--verbose` | Increase verbosity |
| `-d` | `--dir=DIR` | Set stow directory |
| `-t` | `--target=DIR` | Set target directory |

## Adding New Dotfiles

### Single File

```bash
# For ~/.newconfig
touch dotfiles/dot-newconfig

# Apply
stow .

# Verify
ls -la ~/.newconfig
```

### Directory

```bash
# For ~/.config/newapp/
mkdir -p dotfiles/dot-config/newapp
touch dotfiles/dot-config/newapp/config

# Apply
stow .

# Verify
ls -la ~/.config/newapp/
```

### Existing File to Package

1. Move existing file to dotfiles:
   ```bash
   mv ~/.existingrc dotfiles/dot-existingrc
   ```

2. Apply stow:
   ```bash
   stow .
   ```

Or use `--adopt` (careful!):
```bash
# Moves existing files into package, then creates symlinks
stow --adopt .
```

## Handling Conflicts

### What Causes Conflicts

1. **Plain file exists** at target location (not a symlink)
2. **Symlink exists** pointing elsewhere
3. **Directory exists** where symlink should be created
4. **Another package** owns the target

### Resolving Conflicts

**Option 1: Backup and remove**
```bash
mv ~/.conflicting-file ~/.conflicting-file.bak
stow .
```

**Option 2: Use --adopt**
```bash
# Adopts existing file into package (overwrites package file!)
stow --adopt .

# Check what was adopted
git diff
```

**Option 3: Force with restow**
```bash
stow -R .
```

### Conflict Messages

```
WARNING! stowing dotfiles would cause conflicts:
  * existing target is neither a link nor a directory: .zshrc
All operations aborted.
```

Solution: Remove or move the existing `.zshrc` file.

## Tree Folding

Stow optimizes by creating directory symlinks when possible.

### Folded (One Package)

```
# Single package owns directory
~/.config/nvim -> ~/dotfiles/dotfiles/dot-config/nvim
```

### Unfolded (Multiple Packages)

```
# Multiple packages share directory
~/.config/
├── nvim -> ~/dotfiles/dotfiles/dot-config/nvim
├── tmux -> ~/dotfiles/dotfiles/dot-config/tmux
└── starship -> ~/dotfiles/dotfiles/dot-config/starship
```

### Disable Folding

```bash
stow --no-folding .
```

This creates individual file symlinks instead of directory symlinks.

## Ignore Lists

### Priority Order

1. `.stow-local-ignore` in package (overrides defaults)
2. `~/.stow-global-ignore`
3. Built-in defaults

### Default Ignored

- `README.*`, `LICENSE`, `COPYING`
- `.git`, `.gitignore`
- `#*#` (Emacs backup)
- `*~` (backup files)

### Custom Ignore File

Create `.stow-local-ignore` in package:

```bash
# Must re-add desired defaults
\.git
\.gitignore
README.*
LICENSE

# Add custom patterns
Makefile
\.DS_Store
^/.*\.md
```

**Warning:** Creating this file completely overrides defaults.

## Version Control Integration

### .gitignore Considerations

Don't gitignore the stow source files. Only ignore:
- Generated files
- Secrets (handled via `.env` files)
- Machine-specific configs

### Workflow

```bash
# 1. Edit in dotfiles/
nvim dotfiles/dot-config/zsh/aliases.zsh

# 2. Apply changes
stow .

# 3. Test
source ~/.zshrc

# 4. Commit
git add -A
git commit -m "feat: add new alias"
```

## Cross-Platform Usage

### Conditional Configs

Use separate packages or conditional logic in configs:

```bash
dotfiles/
├── dot-zshrc           # Shared config
├── macos/
│   └── dot-zshrc.local # macOS-specific
└── linux/
    └── dot-zshrc.local # Linux-specific
```

Then in `.zshrc`:
```zsh
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
```

### Platform Detection in Configs

```zsh
case "$(uname -s)" in
    Darwin)
        # macOS-specific
        ;;
    Linux)
        # Linux-specific
        ;;
esac
```

## Troubleshooting

### "existing target is not a directory"

```bash
# Remove the conflicting file
rm ~/.conflicting-file
stow .
```

### "existing target is neither a link nor a directory"

The target exists as a regular file. Move/remove it:
```bash
mv ~/.file ~/.file.bak
stow .
```

### Symlinks in Wrong Location

You probably ran `stow <package>` instead of `stow .`:
```bash
# Fix: unstow and restow properly
stow -D <package>
stow .
```

### Stow Not Found

```bash
# macOS
brew install stow

# Ubuntu/Debian
apt install stow

# Fedora
dnf install stow
```

### Verify Symlinks

```bash
# Check a specific file
ls -la ~/.zshrc

# Check all symlinks in home
ls -la ~ | grep "^l"

# Find all symlinks pointing to dotfiles
find ~ -maxdepth 2 -type l -ls 2>/dev/null | grep dotfiles
```

## Best Practices

1. **Always use `stow .`** from project root
2. **Use `stow -n .`** (dry run) before actual stow
3. **Commit before `--adopt`** to see what changed
4. **Keep secrets out** - use `.env` files sourced by configs
5. **Test after stow** - reload configs to verify
6. **Use restow** (`stow -R .`) after removing files from packages
