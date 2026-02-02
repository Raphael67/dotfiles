#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Creates symlinks for Windows-specific dotfiles configurations.
    This is the Windows equivalent of `stow .` for Unix configs.

.PARAMETER DryRun
    Preview what would be linked without making changes.

.PARAMETER Force
    Overwrite existing files/symlinks at target locations.

.EXAMPLE
    .\symlink_windows.ps1 -DryRun
    .\symlink_windows.ps1 -Force
#>
param(
    [switch]$DryRun,
    [switch]$Force
)

$RepoRoot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)

# Resolve actual Documents folder (may be redirected to a different drive)
$DocumentsDir = [Environment]::GetFolderPath('MyDocuments')

# Define symlink mappings: Source (relative to repo root) -> Target (absolute path)
$links = @(
    @{
        Source = "windows\powershell\Microsoft.PowerShell_profile.ps1"
        Target = "$DocumentsDir\PowerShell\Microsoft.PowerShell_profile.ps1"
        Description = "PowerShell 7 profile"
    },
    @{
        Source = "windows\terminal\settings.json"
        Target = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
        Description = "Windows Terminal settings"
    },
    @{
        Source = "dotfiles\dot-config\starship\starship.toml"
        Target = "$HOME\.config\starship\starship.toml"
        Description = "Starship prompt config"
    },
    @{
        Source = "dotfiles\dot-config\Code\User\settings.json"
        Target = "$env:APPDATA\Code\User\settings.json"
        Description = "VS Code settings"
    },
    @{
        Source = "dotfiles\dot-config\bat\config"
        Target = "$HOME\.config\bat\config"
        Description = "bat (cat replacement) config"
    }
)

Write-Host "`n=== Windows Dotfiles Symlink Manager ===" -ForegroundColor Cyan
if ($DryRun) {
    Write-Host "  (DRY RUN - no changes will be made)" -ForegroundColor Yellow
}
Write-Host ""

$created = 0
$skipped = 0
$errors = 0

foreach ($link in $links) {
    $sourcePath = Join-Path $RepoRoot $link.Source
    $targetPath = $link.Target

    # Verify source exists
    if (!(Test-Path $sourcePath)) {
        Write-Host "  SKIP  $($link.Description)" -ForegroundColor Yellow
        Write-Host "        Source not found: $sourcePath" -ForegroundColor DarkYellow
        $skipped++
        continue
    }

    # Create parent directory if needed
    $targetDir = Split-Path -Parent $targetPath
    if (!(Test-Path $targetDir)) {
        if ($DryRun) {
            Write-Host "  MKDIR $targetDir" -ForegroundColor DarkGray
        } else {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
    }

    # Handle existing target
    if (Test-Path $targetPath) {
        $existing = Get-Item $targetPath -Force
        if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -eq $sourcePath) {
            Write-Host "  OK    $($link.Description)" -ForegroundColor DarkGreen
            Write-Host "        Already linked correctly" -ForegroundColor DarkGray
            $skipped++
            continue
        }

        if ($Force) {
            if (!$DryRun) {
                Remove-Item $targetPath -Force
            }
            Write-Host "  DEL   Removed existing: $targetPath" -ForegroundColor Yellow
        } else {
            Write-Host "  EXIST $($link.Description)" -ForegroundColor Yellow
            Write-Host "        $targetPath (use -Force to overwrite)" -ForegroundColor DarkYellow
            $skipped++
            continue
        }
    }

    # Create symlink
    if ($DryRun) {
        Write-Host "  LINK  $($link.Description)" -ForegroundColor Cyan
        Write-Host "        $targetPath" -ForegroundColor DarkGray
        Write-Host "        -> $sourcePath" -ForegroundColor DarkGray
    } else {
        try {
            New-Item -ItemType SymbolicLink -Path $targetPath -Target $sourcePath -Force | Out-Null
            Write-Host "  LINK  $($link.Description)" -ForegroundColor Green
            Write-Host "        $targetPath -> $sourcePath" -ForegroundColor DarkGray
            $created++
        } catch {
            Write-Host "  FAIL  $($link.Description)" -ForegroundColor Red
            Write-Host "        $($_.Exception.Message)" -ForegroundColor DarkRed
            $errors++
        }
    }
}

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
Write-Host "  Created: $created | Skipped: $skipped | Errors: $errors" -ForegroundColor White
if ($DryRun) {
    Write-Host "  (Dry run - run without -DryRun to apply)" -ForegroundColor Yellow
}
Write-Host ""
