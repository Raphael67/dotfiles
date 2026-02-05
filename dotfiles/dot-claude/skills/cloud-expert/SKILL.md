---
name: cloud-expert
description: Expert in cloud storage sync and mounting with rclone. Covers OneDrive (Personal/Business/SharePoint), iCloud Drive, Google Drive setup, OAuth, VFS caching, mounts, and troubleshooting. Use when setting up cloud sync, configuring rclone, mounting cloud storage, or debugging sync issues.
user-invocable: true
argument-hint: [self-update]
version: 1.0.0
---

# Cloud Expert Skill

Expert guidance for cloud storage sync and management using rclone, covering OneDrive, iCloud Drive, and Google Drive backends.

## Quick Reference

| Topic | File | Use When |
|-------|------|----------|
| rclone Core | [RCLONE.md](RCLONE.md) | Commands, flags, VFS caching, filtering, config |
| OneDrive | [ONEDRIVE.md](ONEDRIVE.md) | Personal/Business/SharePoint, Graph API, OAuth |
| Google Drive | [GOOGLE-DRIVE.md](GOOGLE-DRIVE.md) | Google Drive backend, API, quotas, Shared Drives |
| iCloud Drive | [ICLOUD.md](ICLOUD.md) | iCloud backend (experimental), auth, limitations |
| Troubleshooting | [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Errors, debugging, recovery procedures |
| My Setup | [MY-SETUP.md](MY-SETUP.md) | User's keymaging infrastructure, LaunchAgent, remotes |

## Argument Routing

**If $ARGUMENTS is "self-update"**: Read and execute [cookbook/self-update.md](cookbook/self-update.md)

**Otherwise**: Continue with normal skill guidance below.

## Core Principles

### Safety First
- **Always `--dry-run` before destructive operations** (sync, move, delete, dedupe)
- Use `--max-delete` to cap accidental deletions
- Use `--interactive` for manual confirmation on critical ops
- Never store OAuth tokens or config passwords in plaintext

### Backend Selection
| Need | Backend |
|------|---------|
| Microsoft 365 / OneDrive | `onedrive` |
| SharePoint document libraries | `onedrive` with `drive_id` |
| Google Workspace | `drive` |
| iCloud (experimental) | `iclouddrive` |
| Merge multiple remotes | `combine` |
| Encrypt at rest | `crypt` wrapping another remote |

### Performance
- `--fast-list` for recursive listing (essential for large remotes)
- `--transfers N` to parallelize (default 4, increase for small files)
- `--bwlimit` to avoid rate limits on metered connections
- VFS `full` cache mode for mounted filesystems with writes

### Architecture Patterns
- **Combine remote**: Merge Personal OneDrive + SharePoint libraries into one mount
- **Crypt remote**: Wrap any backend with encryption (config-level, transparent)
- **NFS mount**: `rclone nfsmount` for macOS (avoids FUSE/macFUSE dependency)
- **LaunchAgent**: Persistent mount on macOS via `~/Library/LaunchAgents/`

## When to Read Reference Files

**Read RCLONE.md when:**
- Installing or updating rclone
- Choosing between sync/copy/bisync/mount
- Configuring VFS cache modes or tuning
- Setting up filtering rules
- Debugging with log levels

**Read ONEDRIVE.md when:**
- Setting up OneDrive Personal or Business
- Accessing SharePoint document libraries
- Dealing with OAuth token refresh
- Hitting OneDrive-specific limits or quirks

**Read GOOGLE-DRIVE.md when:**
- Setting up Google Drive backend
- Configuring custom Client ID (avoid rate limits)
- Handling Google Docs export formats
- Working with Shared Drives

**Read ICLOUD.md when:**
- Setting up iCloud Drive access
- Dealing with 2FA trust tokens
- Understanding experimental backend limitations

**Read TROUBLESHOOTING.md when:**
- Auth failures or token expiry
- Mount won't start or is unstable
- Rate limiting or quota errors
- VFS cache corruption
- LaunchAgent issues on macOS

**Read MY-SETUP.md when:**
- Understanding the user's existing rclone infrastructure
- Modifying the keymaging combine remote
- Adding new SharePoint sites
- Debugging the LaunchAgent mount
- Working with `scripts/setup-rclone.sh`

## Quick Wins

```bash
# Test connection to a remote
rclone lsd remote: --max-depth 1

# Dry-run sync (preview changes)
rclone sync source: dest: --dry-run --progress

# Mount with full VFS cache
rclone nfsmount remote: /mount/point --vfs-cache-mode full

# Check config encryption
rclone config show  # prompts for password if encrypted

# View live logs
tail -f ~/Library/Logs/rclone-keymaging.log

# Check quota/usage
rclone about remote:
```

## Common Patterns

### OneDrive Business Setup
```bash
rclone config create onedrive-personal onedrive
# Follow OAuth flow → choose "OneDrive Personal or Business" → drive type "business"
```

### SharePoint Library Access
```bash
# Discover sites via Graph API, then:
rclone config create sp-mylib onedrive \
  token "$TOKEN" drive_id "$DRIVE_ID" drive_type documentLibrary
```

### Combine Remote (Merge Multiple)
```bash
rclone config create keymaging combine \
  upstreams "Personal=onedrive-personal: Docs=sp-docs:"
```

### Encrypted Config
```bash
# Set password
rclone config  # → 's) Set configuration password'

# Store in macOS Keychain
security add-generic-password -a rclone -s rclone-config -w "$PASSWORD"

# Use in env
export RCLONE_PASSWORD_COMMAND="security find-generic-password -a rclone -s rclone-config -w"
```

### LaunchAgent (Persistent Mount)
```xml
<key>ProgramArguments</key>
<array>
    <string>/opt/homebrew/bin/rclone</string>
    <string>nfsmount</string>
    <string>keymaging:</string>
    <string>/Volumes/keymaging</string>
    <string>--vfs-cache-mode</string>
    <string>full</string>
</array>
```

## Safety Guidelines

### Destructive Operations
- `rclone sync` **deletes** files in dest not in source — always `--dry-run` first
- `rclone move` deletes source after transfer — use `rclone copy` if unsure
- `rclone dedupe` modifies remote content — back up first
- `--max-delete N` caps deletions (absolute count or percentage with `%`)

### Token Security
- OAuth tokens grant full access to cloud storage — treat as secrets
- Config encryption (`RCLONE_ENCRYPT_V0`) protects tokens at rest
- Use `RCLONE_PASSWORD_COMMAND` to avoid plaintext passwords in scripts
- Keychain storage is preferred on macOS

### Mount Safety
- Unmount cleanly before removing LaunchAgent: `umount /Volumes/keymaging`
- If mount hangs: `diskutil unmount force /Volumes/keymaging`
- VFS cache lives in `~/.cache/rclone/vfs/` — can grow large, monitor disk

## Quick Command Reference

| Command | Purpose |
|---------|---------|
| `rclone sync src: dst:` | One-way sync (dst mirrors src) |
| `rclone copy src: dst:` | Copy files (no deletes) |
| `rclone move src: dst:` | Move files (deletes source) |
| `rclone bisync src: dst:` | Two-way sync |
| `rclone mount remote: /path` | FUSE mount |
| `rclone nfsmount remote: /path` | NFS mount (macOS, no FUSE) |
| `rclone serve webdav remote:` | Serve as WebDAV |
| `rclone check src: dst:` | Compare without transfer |
| `rclone dedupe remote:` | Remove duplicates |
| `rclone about remote:` | Show quota/usage |
| `rclone config show` | Dump config (decrypted) |
| `rclone listremotes` | List configured remotes |
| `rclone lsd remote:` | List directories |
| `rclone ls remote:` | List files with sizes |
