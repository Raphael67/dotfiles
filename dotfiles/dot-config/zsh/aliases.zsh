# less
alias less="less -iR"

# System
alias shutdown='sudo shutdown now'
alias restart='sudo reboot'
alias suspend='sudo pm-suspend'
alias sleep='pmset sleepnow'
alias c='clear'
alias e='exit'

# Git
alias g='git'
alias ga='git add'
alias gafzf='git ls-files -m -o --exclude-standard | grep -v "__pycache__" | fzf -m --print0 | xargs -0 -o -t git add' # Git add with fzf
alias gap="git add --patch"
alias gb='git branch '
alias gbr='git branch -r'
alias gc='git commit -v'
alias gcanenv='git commit --amend --no-edit --no-verify'
alias gcl="git clone"
alias gcmnv='git commit --no-verify -m'
alias gco='git checkout '
alias gcofzf='git branch | fzf | xargs git checkout' # Select branch with fzf
alias gd="git diff --output-indicator-new=' ' --output-indicator-old=' ' --color=always"
alias gds="git diff --staged"
alias gf='git fetch'
alias ggpush='git push origin $(current_branch)'
alias gi="git init"
alias gl="git log --all --graph --pretty=format:'%C(magenta)%h %C(white) %an %ar%C(auto) %D%n%s%n'"
alias glgg='git log --graph --max-count=5 --decorate --pretty="oneline"'
alias gm='git merge'
alias gp='git push'
alias gpo='git push origin'
alias gre='git remote'
alias gres='git remote show'
alias grfzf='git diff --name-only | fzf -m --print0 | xargs -0 -o -t git restore'              # Git restore with fzf
alias grmfzf='git ls-files -m -o --exclude-standard | fzf -m --print0 | xargs -0 -o -t git rm' # Git rm with fzf
alias grsfzf='git diff --name-only | fzf -m --print0 | xargs -0 -o -t git restore --staged'    # Git restore --staged with fzf
alias gs="git status --short --branch"
alias gtd='git tag --delete'
alias gtdr='git tag --delete origin'
alias gu="git pull"
alias gup='git fetch && git rebase'

# Function to commit with ticket ID from current branch, with optional push
quick_commit() {
    local branch_name ticket_id commit_message push_flag
    branch_name=$(git branch --show-current)
    ticket_id=$(echo "$branch_name" | awk -F '-' '{print toupper($1"-"$2)}')
    commit_message="$ticket_id: $*"
    push_flag=$1

    if [[ "$push_flag" == "push" ]]; then
        # Remove 'push' from the commit message
        commit_message="$ticket_id: ${*:2}" # take all positional parameters starting from the second one
        git commit --no-verify -m "$commit_message" && git push
    else
        git commit --no-verify -m "$commit_message"
    fi
}

alias gqc='quick_commit'
alias gqcp='quick_commit push'

# Neovim
# If poetry is installed and an environment exists, run "poetry run nvim"
poetry_run_nvim() {
    if command -v poetry >/dev/null 2>&1 && [ -f "poetry.lock" ]; then
        poetry run nvim "$@"
    else
        nvim "$@"
    fi
}
alias vi='poetry_run_nvim'
alias v='poetry_run_nvim'

# Folders
alias doc="$HOME/Documents"
alias dow="$HOME/Downloads"

# Ranger
alias r=". ranger"

# Better ls
alias ls="eza --all --icons=always"

# Lazygit
alias lg="lazygit"

# New obsidian notes in nvim
alias oo="cd /Users/raphael/Library/Mobile Documents/iCloud~md~obsidian/Documents ; v ."

# Open new Ghostty window without tmux
alias notmux='open -na Ghostty.app --args --command=$HOME/.local/bin/zsh-notmux'

# hys: filter recent news (last 48 hours)
alias news="$HOME/Projects/hys-fork/zig-out/bin/hys --all -p 48"

# Fix stuck mouse reporting mode (when scrolling outputs escape sequences)
alias fixmouse="printf '\e[?1000l\e[?1002l\e[?1003l\e[?1006l'"

alias clyo="claude --dangerously-skip-permissions"
alias gemini="npx https://github.com/google-gemini/gemini-cli"
