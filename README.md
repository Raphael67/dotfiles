# My dotfiles

This directory contains the dotfiles for my system

# Dotfiles

## Installation

```
./setup.sh
```

# Git hook

Add a pre-commit hook to avoid leaking secrets

```
cp ./hooks/pre-commit .git/hooks
```

# Karabiner

If Karabiner does not work, you should look at this issue:
https://github.com/pqrs-org/Karabiner-Elements/issues/3620

# Ghostty

Copy Ghostty terminal settings to SSH servers:

```bash
infocmp -x xterm-ghostty | ssh user@server 'tic -x -'
```

# Inspired by

- https://github.com/omerxx/dotfiles
- https://github.com/elliottminns/dotfiles
- https://github.com/hendrikmi/dotfiles
- https://gitlab.com/obxhdx/dotfiles
