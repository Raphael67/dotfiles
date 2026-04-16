# Windows Setup

## Package Management Strategy

Windows uses **WinGet** as the sole package manager.

| Tier | Tool | Config file | When used |
|------|------|-------------|-----------|
| Primary | WinGet | `winget/packages.json` | All packages |
| Post-install | bun/npm | inline in `setup_windows.ps1` | npm-distributed CLIs (claude-code) |

## Running the setup

```powershell
# Full setup (requires admin)
.\setup_windows.ps1

# Skip specific steps
.\setup_windows.ps1 -SkipWinGet      # post-install only
.\setup_windows.ps1 -SkipApps        # no package installation at all
.\setup_windows.ps1 -SkipWSL         # skip WSL2 config
.\setup_windows.ps1 -SkipSymlinks    # skip symlink creation
```

## WinGet packages (`winget/packages.json`)

Installed via `winget import`. All packages verified against the winget source.

| Package | WinGet ID |
|---------|-----------|
| 7-Zip | `7zip.7zip` |
| uv (Python) | `astral-sh.uv` |
| Deno | `DenoLand.Deno` |
| Bun | `Oven-sh.Bun` |
| FFmpeg | `Gyan.FFmpeg` |
| Git | `Git.Git` |
| k9s | `Derailed.k9s` |
| kubectl | `Kubernetes.kubectl` |
| Helm | `Helm.Helm` |
| Make (GnuWin32) | `GnuWin32.Make` |
| Nmap | `Insecure.Nmap` |
| NVM for Windows | `CoreyButler.NVMforWindows` |
| OpenJDK 21 | `Microsoft.OpenJDK.21` |
| PuTTY | `PuTTY.PuTTY` |
| Sourcetree | `Atlassian.Sourcetree` |
| Wget | `JernejSimoncic.Wget` |
| Wireshark | `WiresharkFoundation.Wireshark` |
| VS Code | `Microsoft.VisualStudioCode` |
| Gitleaks | `Gitleaks.Gitleaks` |
| Starship | `Starship.Starship` |
| bat | `sharkdp.bat` |
| eza | `eza-community.eza` |
| fzf | `junegunn.fzf` |
| zoxide | `ajeetdsouza.zoxide` |
| lazygit | `JesseDuffield.lazygit` |
| ripgrep | `BurntSushi.ripgrep.MSVC` |
| fd | `sharkdp.fd` |
| Bambu Studio | `Bambulab.Bambustudio` |
| Google Chrome | `Google.Chrome` |
| Obsidian | `Obsidian.Obsidian` |
| OpenVPN | `OpenVPNTechnologies.OpenVPN` |
| Slack | `SlackTechnologies.Slack` |

## Post-install: claude-code CLI

`claude-code` is the Anthropic CLI — it is not in winget.
The setup script installs it via the official Anthropic installer:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Note: `Anthropic.Claude` in winget is the **desktop app**, not the CLI.

## Adding a new package

1. Check winget first: `winget search <name>`
2. If found: add `{ "PackageIdentifier": "<ID>" }` to `winget/packages.json` under `Packages`
3. If not available in winget, consider whether the package is still needed
