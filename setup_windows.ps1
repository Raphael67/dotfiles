#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows dotfiles setup script.
    Installs packages, PowerShell modules, configures WSL, and creates symlinks.

.PARAMETER SkipApps
    Skip Chocolatey package installation.

.PARAMETER SkipWSL
    Skip WSL configuration.

.PARAMETER SkipSymlinks
    Skip symlink creation.

.EXAMPLE
    .\setup_windows.ps1
    .\setup_windows.ps1 -SkipApps
#>
param(
    [switch]$SkipApps,
    [switch]$SkipWSL,
    [switch]$SkipSymlinks
)

Set-ExecutionPolicy Bypass -Scope Process -Force

$ScriptDir = Split-Path -Parent $PSCommandPath

Write-Host "`n=== Dotfiles Windows Setup ===" -ForegroundColor Cyan
Write-Host ""

#region Chocolatey
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    Write-Host "Chocolatey installed." -ForegroundColor Green
} else {
    Write-Host "Chocolatey already installed." -ForegroundColor DarkGray
}
#endregion

#region Install Packages
if (!$SkipApps) {
    Write-Host "`n--- Installing Chocolatey Packages ---" -ForegroundColor Cyan
    $packages = Get-Content "$ScriptDir\choco\packages.txt" | Where-Object { $_ -and $_ -notmatch '^\s*#' }
    foreach ($pkg in $packages) {
        $pkg = $pkg.Trim()
        if ($pkg) {
            Write-Host "  Installing $pkg..." -ForegroundColor Gray
            choco install -y $pkg
        }
    }
    Write-Host "Packages installed." -ForegroundColor Green
} else {
    Write-Host "Skipping package installation." -ForegroundColor DarkGray
}
#endregion

#region PowerShell Modules
Write-Host "`n--- Installing PowerShell Modules ---" -ForegroundColor Cyan
$modules = @('Terminal-Icons', 'PSFzf')
foreach ($mod in $modules) {
    if (!(Get-Module -ListAvailable -Name $mod)) {
        Write-Host "  Installing $mod..." -ForegroundColor Gray
        Install-Module -Name $mod -Scope CurrentUser -Force -AcceptLicense
        Write-Host "  $mod installed." -ForegroundColor Green
    } else {
        Write-Host "  $mod already installed." -ForegroundColor DarkGray
    }
}

# Ensure PSReadLine is up to date
$psrl = Get-Module -ListAvailable -Name PSReadLine | Sort-Object Version -Descending | Select-Object -First 1
if ($psrl.Version -lt [version]"2.3.0") {
    Write-Host "  Updating PSReadLine..." -ForegroundColor Gray
    Install-Module -Name PSReadLine -Scope CurrentUser -Force -AllowPrerelease -AcceptLicense
    Write-Host "  PSReadLine updated." -ForegroundColor Green
} else {
    Write-Host "  PSReadLine is up to date ($($psrl.Version))." -ForegroundColor DarkGray
}
#endregion

#region WSL
if (!$SkipWSL) {
    Write-Host "`n--- Configuring WSL ---" -ForegroundColor Cyan
    wsl --set-default-version 2
    Write-Host "WSL2 set as default." -ForegroundColor Green
    Write-Host "  Ensure Arch Linux WSL is installed." -ForegroundColor Yellow
    Write-Host "  To set up dotfiles inside WSL:" -ForegroundColor Yellow
    Write-Host "    wsl -d archlinux" -ForegroundColor White
    Write-Host "    git clone <your-repo-url> ~/dotfiles" -ForegroundColor White
    Write-Host "    cd ~/dotfiles && ./setup_archlinux.sh" -ForegroundColor White
} else {
    Write-Host "Skipping WSL configuration." -ForegroundColor DarkGray
}
#endregion

#region Symlinks
if (!$SkipSymlinks) {
    Write-Host "`n--- Creating Symlinks ---" -ForegroundColor Cyan
    & "$ScriptDir\scripts\symlink_windows.ps1" -Force
} else {
    Write-Host "Skipping symlink creation." -ForegroundColor DarkGray
}
#endregion

#region Config Generation
$template = Join-Path $ScriptDir "dotfiles\dot-config\.jira\.config.yml.template"
if (Test-Path $template) {
    Write-Host "`n--- Generating Jira CLI config ---" -ForegroundColor Cyan
    $envFile = Join-Path $ScriptDir ".env"
    if (Test-Path $envFile) {
        Get-Content $envFile | ForEach-Object {
            if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
                [System.Environment]::SetEnvironmentVariable($Matches[1].Trim(), $Matches[2].Trim(), "Process")
            }
        }
    }
    $content = Get-Content $template -Raw
    $content = [regex]::Replace($content, '\$\{(\w+)\}', { param($m) [System.Environment]::GetEnvironmentVariable($m.Groups[1].Value) })
    $dest = Join-Path $env:USERPROFILE ".config\.jira\.config.yml"
    New-Item -ItemType Directory -Path (Split-Path $dest) -Force | Out-Null
    Set-Content -Path $dest -Value $content -NoNewline
    Write-Host "Jira CLI config generated." -ForegroundColor Green
}
#endregion

#region Summary
Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Restart your terminal to load the new PowerShell profile" -ForegroundColor White
Write-Host "  2. Verify starship prompt loads (you should see a styled prompt)" -ForegroundColor White
Write-Host "  3. Test tools: starship --version, bat --version, eza --version" -ForegroundColor White
Write-Host "  4. For WSL Arch setup: wsl -d archlinux, then run setup_archlinux.sh" -ForegroundColor White
Write-Host ""
#endregion
