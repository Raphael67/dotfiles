# Windows Setup

## Package Management Strategy

Windows uses a two-tier approach: **WinGet first, Chocolatey as fallback**.

| Tier | Tool | Config file | When used |
|------|------|-------------|-----------|
| Primary | WinGet | `winget/packages.json` | All packages available in the winget source |
| Fallback | Chocolatey | `choco/packages.txt` | Packages not (yet) in winget |
| Post-install | bun/npm | inline in `setup_windows.ps1` | npm-distributed CLIs (claude-code) |

## Running the setup

```powershell
# Full setup (requires admin)
.\setup_windows.ps1

# Skip specific steps
.\setup_windows.ps1 -SkipWinGet      # choco + post-install only
.\setup_windows.ps1 -SkipChoco       # winget + post-install only
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

## Chocolatey fallback packages (`choco/packages.txt`)

Only packages with no winget equivalent.

| Package | Notes |
|---------|-------|
| `dotnet4.7.1` | Legacy .NET Framework — no exact winget match |
| `dotnetfx` | Legacy .NET Framework runtime |
| `processhacker` | Discontinued; successor is `WinsiderSS.SystemInformer` in winget |

### Note on ProcessHacker

ProcessHacker is discontinued upstream. Its successor, **System Informer**, is available in winget:

```powershell
winget install WinsiderSS.SystemInformer
```

Consider switching to System Informer and removing `processhacker` from the choco list.

## Post-install: claude-code CLI

`claude-code` is the Anthropic CLI distributed as an npm package — it is not in winget.
The setup script installs it via `bun` (preferred) or `npm` after they are available:

```powershell
bun install -g @anthropic-ai/claude-code
# or
npm install -g @anthropic-ai/claude-code
```

Note: `Anthropic.Claude` in winget is the **desktop app**, not the CLI.

## Adding a new package

1. Check winget first: `winget search <name>`
2. If found: add `{ "PackageIdentifier": "<ID>" }` to `winget/packages.json` under `Packages`
3. If not found: add the package name to `choco/packages.txt`
