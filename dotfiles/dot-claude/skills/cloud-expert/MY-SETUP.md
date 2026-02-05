# My Setup: keymaging Infrastructure

This documents the user's specific rclone infrastructure for cloud storage mounting.

## Overview

All OneDrive for Business + SharePoint document libraries are merged into a single NFS mount at `/Volumes/keymaging` via rclone's combine remote, running as a macOS LaunchAgent.

## Architecture

```
┌─────────────────────────────────────────────────┐
│              /Volumes/keymaging (NFS mount)       │
│                                                   │
│  Personal/          → onedrive-personal:          │
│  bizdev-clients/    → sp-bizdev-clients:          │
│  communication/     → sp-communication-mailing:   │
│  ...                → sp-*:                       │
└───────────────────────┬─────────────────────────┘
                        │
                  keymaging: (combine remote)
                        │
         ┌──────────────┼──────────────────┐
         │              │                  │
  onedrive-personal:  sp-lib1:  ...  sp-libN:
  (OneDrive Business) (SharePoint document libraries)
         │              │
         └──────┬───────┘
           onedrive-shared: (token source for SharePoint)
```

## Config Encryption

- `rclone.conf` is encrypted with `RCLONE_ENCRYPT_V0` (NaCl secretbox)
- Password stored in macOS Keychain: account `rclone`, service `rclone-config`
- Retrieved at runtime via: `RCLONE_PASSWORD_COMMAND="security find-generic-password -a rclone -s rclone-config -w"`
- All rclone commands (including LaunchAgent) use this env var to decrypt config

## Remote Structure

### onedrive-personal
- Type: `onedrive`
- Drive type: `business` (OneDrive for Business)
- Contains personal files
- Mounted as `Personal/` in keymaging

### onedrive-shared
- Type: `onedrive`
- Points to SharePoint root site
- **Primary purpose:** Token source for SharePoint library discovery
- Not directly mounted — its OAuth token is reused to create `sp-*` remotes

### sp-* (SharePoint libraries)
- Type: `onedrive` with `drive_type = documentLibrary`
- Each points to a specific SharePoint document library via `drive_id`
- Created programmatically by `scripts/setup-rclone.sh`
- Naming: `sp-{site-name}-{library-name}` (sanitized, lowercase, hyphens)
- Token reused from `onedrive-shared`

### keymaging (combine remote)
- Type: `combine`
- Merges `onedrive-personal:` + all `sp-*:` remotes
- Upstreams format: `Personal=onedrive-personal: lib-name=sp-lib-name:`
- The `sp-` prefix is stripped in the mount path (e.g., `sp-bizdev-clients:` → `bizdev-clients/`)

## LaunchAgent

**Plist:** `~/Library/LaunchAgents/com.rclone.keymaging.plist`
(Source: `dotfiles/Library/LaunchAgents/com.rclone.keymaging.plist`)

### Configuration
| Setting | Value |
|---------|-------|
| Command | `/opt/homebrew/bin/rclone nfsmount keymaging: /Volumes/keymaging` |
| VFS cache mode | `full` |
| NFS cache type | `disk` (persistent handles) |
| VFS refresh | enabled |
| Poll interval | `1m` |
| Dir cache time | `5m` |
| VFS cache max size | `10G` |
| VFS cache max age | `72h` |
| Volume name | `keymaging` |
| Log file | `~/Library/Logs/rclone-keymaging.log` |
| Log level | `NOTICE` |
| Run at load | `true` |
| Keep alive | `true` |

### Management
```bash
# Start
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist

# Stop
launchctl bootout gui/$(id -u)/com.rclone.keymaging

# Restart
launchctl bootout gui/$(id -u)/com.rclone.keymaging && \
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist

# Check status
launchctl list | grep rclone

# View logs
tail -f ~/Library/Logs/rclone-keymaging.log
```

## Setup Script

**Path:** `scripts/setup-rclone.sh` (in dotfiles repo)

### What It Does (8 steps)
1. **Configure base remotes** — Interactive `rclone config` for `onedrive-personal` and `onedrive-shared`
2. **Set config encryption** — Encrypt `rclone.conf` with a password
3. **Store password in Keychain** — `security add-generic-password -a rclone -s rclone-config -w`
4. **Verify config decryption** — Test that `RCLONE_PASSWORD_COMMAND` works
5. **Create SharePoint library remotes** — Python script that:
   - Extracts OAuth token from `onedrive-shared`
   - Calls Graph API to discover all SharePoint sites
   - Filters out system sites (Root, Team Site, Hub, Apps, Designer, etc.)
   - Creates `sp-*` remotes for each document library
   - Builds the `keymaging` combine remote with all upstreams
6. **Create mount point** — `sudo mkdir -p /Volumes/keymaging`
7. **Test remote access** — `rclone lsd keymaging: --max-depth 1`
8. **Load LaunchAgent** — Bootstrap the plist

### Site Filtering
The script skips these SharePoint sites:
- Names: `Site Racine`, `Site d'équipe`, `Site hub de pointpublishing`, `Apps`, `Designer`, `Admins Git`
- URL patterns: `contentstorage`, `portals`, `appcatalog`, `contentTypeHub`
- Drive names: `Teams Wiki Data`

## Maintenance

### Adding New SharePoint Sites
Re-run the setup script's Step 5 (SharePoint discovery). It skips existing remotes and only creates new ones. Then reload the LaunchAgent.

Alternatively, manually:
```bash
# Get token from existing remote
export RCLONE_PASSWORD_COMMAND="security find-generic-password -a rclone -s rclone-config -w"
TOKEN=$(rclone config show onedrive-shared | grep 'token =' | cut -d'=' -f2-)

# Create remote
rclone config create sp-new-site onedrive \
  token "$TOKEN" drive_id "$DRIVE_ID" drive_type documentLibrary

# Update combine remote
UPSTREAMS=$(rclone config show keymaging | grep 'upstreams =' | cut -d'=' -f2-)
rclone config update keymaging upstreams "$UPSTREAMS new-site=sp-new-site:"

# Restart mount
launchctl bootout gui/$(id -u)/com.rclone.keymaging
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
```

### Token Refresh
OneDrive tokens expire after 90 days of inactivity. If auth fails:
```bash
export RCLONE_PASSWORD_COMMAND="security find-generic-password -a rclone -s rclone-config -w"

# Re-authorize the base remote
rclone config reconnect onedrive-personal

# For SharePoint: reconnect shared, then re-run setup to propagate token
rclone config reconnect onedrive-shared
# Re-run scripts/setup-rclone.sh Step 5
```

### LaunchAgent Reload
After changing the plist in dotfiles:
```bash
# Restow
cd ~/Projects/dotfiles && stow .

# Reload
launchctl bootout gui/$(id -u)/com.rclone.keymaging
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
```

### Monitoring
```bash
# Mount status
mount | grep keymaging

# Process status
pgrep -fl "rclone.*nfsmount"

# Cache size
du -sh ~/.cache/rclone/vfs/keymaging/

# Quota
rclone about onedrive-personal:

# Live logs
tail -f ~/Library/Logs/rclone-keymaging.log
```
