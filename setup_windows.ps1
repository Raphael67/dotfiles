#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Windows dotfiles setup script.
    Installs packages, PowerShell modules, configures WSL, and creates symlinks.

.DESCRIPTION
    Package installation order:
      1. WinGet  — primary, installs from winget/packages.json
      2. Choco   — fallback for packages unavailable in WinGet (choco/packages.txt)
      3. Post-install steps for tools distributed via npm/bun (e.g. claude-code CLI)

.PARAMETER SkipApps
    Skip all package installation (WinGet + Choco).

.PARAMETER SkipWinGet
    Skip WinGet package installation only.

.PARAMETER SkipChoco
    Skip Chocolatey fallback package installation only.

.PARAMETER SkipWSL
    Skip WSL configuration.

.PARAMETER SkipSymlinks
    Skip symlink creation.

.EXAMPLE
    .\setup_windows.ps1
    .\setup_windows.ps1 -SkipApps
    .\setup_windows.ps1 -SkipWinGet
#>
param(
    [switch]$SkipApps,
    [switch]$SkipWinGet,
    [switch]$SkipChoco,
    [switch]$SkipWSL,
    [switch]$SkipSymlinks
)

Set-ExecutionPolicy Bypass -Scope Process -Force

$ScriptDir = Split-Path -Parent $PSCommandPath

Write-Host "`n=== Dotfiles Windows Setup ===" -ForegroundColor Cyan
Write-Host ""

#region WinGet
if (!$SkipApps -and !$SkipWinGet) {
    Write-Host "`n--- Installing packages via WinGet ---" -ForegroundColor Cyan

    $wingetManifest = "$ScriptDir\winget\packages.json"

    if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
        Write-Host "  WinGet not found. Install App Installer from the Microsoft Store." -ForegroundColor Red
        Write-Host "  Skipping WinGet installation." -ForegroundColor Yellow
    } elseif (!(Test-Path $wingetManifest)) {
        Write-Host "  Manifest not found: $wingetManifest" -ForegroundColor Red
    } else {
        Write-Host "  Running: winget import --import-file $wingetManifest" -ForegroundColor Gray
        winget import --import-file $wingetManifest --accept-package-agreements --accept-source-agreements --ignore-unavailable
        if ($LASTEXITCODE -eq 0) {
            Write-Host "WinGet packages installed." -ForegroundColor Green
        } else {
            Write-Host "WinGet import completed with warnings (exit code $LASTEXITCODE)." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "Skipping WinGet package installation." -ForegroundColor DarkGray
}
#endregion

#region Chocolatey fallback
if (!$SkipApps -and !$SkipChoco) {
    Write-Host "`n--- Installing Chocolatey fallback packages ---" -ForegroundColor Cyan

    # Bootstrap Choco only if there are actual packages to install
    $chocoPackages = Get-Content "$ScriptDir\choco\packages.txt" |
        Where-Object { $_ -and $_ -notmatch '^\s*#' } |
        ForEach-Object { $_.Trim() } |
        Where-Object { $_ }

    if ($chocoPackages.Count -eq 0) {
        Write-Host "  No Chocolatey fallback packages to install." -ForegroundColor DarkGray
    } else {
        # Install Chocolatey if not present
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Host "  Installing Chocolatey..." -ForegroundColor Yellow
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "  Chocolatey installed." -ForegroundColor Green
        } else {
            Write-Host "  Chocolatey already installed." -ForegroundColor DarkGray
        }

        foreach ($pkg in $chocoPackages) {
            Write-Host "  Installing $pkg (choco)..." -ForegroundColor Gray
            choco install -y $pkg
        }
        Write-Host "Chocolatey fallback packages installed." -ForegroundColor Green
    }
} else {
    Write-Host "Skipping Chocolatey package installation." -ForegroundColor DarkGray
}
#endregion

#region Post-install: claude-code CLI
if (!$SkipApps) {
    Write-Host "`n--- Post-install: claude-code CLI ---" -ForegroundColor Cyan
    # Install via the official Anthropic installer.
    Write-Host "  Installing claude via official Anthropic installer..." -ForegroundColor Gray
    irm https://claude.ai/install.ps1 | iex
    Write-Host "  claude-code installed." -ForegroundColor Green
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
