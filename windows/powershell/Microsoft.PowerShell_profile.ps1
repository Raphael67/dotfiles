# PowerShell 7 Profile
# Cross-platform dotfiles: Windows power-user configuration
# Mirrors macOS zsh workflow where applicable

#region Encoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8
#endregion

#region Environment
$env:EDITOR = "code --wait"
$env:STARSHIP_CONFIG = "$HOME\.config\starship\starship.toml"
$env:FZF_DEFAULT_OPTS = @"
--color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 --color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 --color=selected-bg:#494d64 --multi
"@
$env:COLORTERM = "truecolor"
#endregion

#region PSReadLine
if ((Get-Module -ListAvailable -Name PSReadLine) -and [System.Console]::IsOutputRedirected -eq $false) {
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Set-PSReadLineOption -EditMode Windows
    Set-PSReadLineOption -BellStyle None
    Set-PSReadLineOption -HistorySearchCursorMovesToEnd
    Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
    Set-PSReadLineKeyHandler -Chord 'Ctrl+d' -Function DeleteCharOrExit
    Set-PSReadLineKeyHandler -Chord 'Ctrl+w' -Function BackwardDeleteWord
}
#endregion

#region Modules
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}
if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+t' -PSReadlineChordReverseHistory 'Ctrl+r'
}
#endregion

#region Navigation
function dev { Set-Location D:\Projects }
function home { Set-Location $HOME }
function .. { Set-Location .. }
function ... { Set-Location ..\.. }
function .... { Set-Location ..\..\.. }
#endregion

#region Git Aliases (mirrors zsh aliases.zsh)
function g { git @args }
function ga { git add @args }
function gap { git add --patch @args }
function gb { git branch @args }
function gbr { git branch -r @args }
function gc { git commit -v @args }
function gcanenv { git commit --amend --no-edit --no-verify @args }
function gcl { git clone @args }
function gcmnv { git commit --no-verify -m @args }
function gco { git checkout @args }
function gd { git diff @args }
function gds { git diff --staged @args }
function gf { git fetch @args }
function gi { git init @args }
function gl { git log --all --graph --pretty=format:'%C(magenta)%h %C(white) %an %ar%C(auto) %D%n%s%n' @args }
function glgg { git log --graph --max-count=5 --decorate --pretty="oneline" @args }
function gm { git merge @args }
function gp { git push @args }
function gpo { git push origin @args }
function gs { git status --short --branch @args }
function gtd { git tag --delete @args }
function gtdr { git tag --delete origin @args }
function gu { git pull @args }
function gup { git fetch; git rebase @args }
function gre { git remote @args }
function gres { git remote show @args }
#endregion

#region Tool Aliases
# lazygit
if (Get-Command lazygit -ErrorAction SilentlyContinue) {
    Set-Alias -Name lg -Value lazygit
}

# nvim
if (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias -Name v -Value nvim
    Set-Alias -Name vi -Value nvim
}

# kubectl
if (Get-Command kubectl -ErrorAction SilentlyContinue) {
    Set-Alias -Name k -Value kubectl
}

# bat (as ccat, not overriding cat/Get-Content)
if (Get-Command bat -ErrorAction SilentlyContinue) {
    function ccat { bat --style=plain --paging=auto @args }
}

# eza (as lss/ll/la, not overriding ls/Get-ChildItem)
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function lss { eza -g -s Name --group-directories-first --time-style long-iso --icons=auto @args }
    function ll { eza -lg -s Name --group-directories-first --time-style long-iso --icons=auto @args }
    function la { eza -lga -s Name --group-directories-first --time-style long-iso --icons=auto @args }
}
# claude
if (Get-Command claude -ErrorAction SilentlyContinue) {
    function clyo { claude --dangerously-skip-permissions @args }
}

#region Docker
if (Get-Command docker -ErrorAction SilentlyContinue) {
    function d { docker @args }
    function dps { docker ps @args }
    function dpa { docker ps -a @args }
}
#endregion

#region Utility Functions
function which { param([string]$Name) Get-Command $Name -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source }
function touch {
    param([string]$Path)
    if (!(Test-Path $Path)) { New-Item $Path -ItemType File | Out-Null }
    else { (Get-Item $Path).LastWriteTime = Get-Date }
}
function mkcd {
    param([string]$Path)
    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location $Path
}
function sysinfo {
    Get-ComputerInfo | Select-Object CsName, WindowsProductName, WindowsVersion, OsArchitecture, CsProcessors, CsTotalPhysicalMemory
}
function cleanup {
    Write-Host "Cleaning temp files..." -ForegroundColor Cyan
    $before = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    $after = (Get-ChildItem $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $freed = [math]::Round(($before - $after) / 1MB, 2)
    Write-Host "Freed ${freed}MB" -ForegroundColor Green
}
function c { Clear-Host }
function e { exit }
#endregion

#region Zoxide (smart cd replacement, same as zsh config)
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell --cmd cd | Out-String) })
}
#endregion

#region Starship Prompt (must be last)
if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
#endregion
