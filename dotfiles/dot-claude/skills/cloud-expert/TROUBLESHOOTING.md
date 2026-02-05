# Troubleshooting Reference

## Authentication Errors

### OneDrive: "token expired" / 401 Unauthorized
```bash
# Re-authorize the remote
rclone config reconnect onedrive-personal

# If using encrypted config, ensure password command works
security find-generic-password -a rclone -s rclone-config -w
```
**Cause:** Refresh token expired (90 days of inactivity) or revoked by admin.

### OneDrive: "AADSTS700082: refresh token has expired"
Same as above. Refresh tokens expire after 90 days without use. Run `rclone config reconnect <remote>`.

### Google Drive: "oauth2: token expired and refresh token is not set"
```bash
rclone config reconnect gdrive
```
**Cause:** Refresh token revoked (user revoked app access in Google Account settings) or scope change.

### Google Drive: "rateLimitExceeded" / 403
- Reduce `--transfers` and `--tpslimit`
- Wait 1-2 minutes for quota reset
- Switch to custom Client ID if using shared

### iCloud: "Authentication failed"
1. Verify using Apple ID password (not app-specific)
2. Disable Advanced Data Protection
3. Enable "Access iCloud Data on the Web"
4. Run `rclone reconnect icloud:` and complete 2FA

### Config password errors
```bash
# Test password retrieval
security find-generic-password -a rclone -s rclone-config -w

# If empty or wrong, update
security delete-generic-password -a rclone -s rclone-config
security add-generic-password -a rclone -s rclone-config -w "newpassword"
```

## Mount Issues

### Mount fails to start

#### "mount point not found"
```bash
sudo mkdir -p /Volumes/keymaging
sudo chown "$USER" /Volumes/keymaging
```

#### "address already in use" (NFS mount)
Another rclone instance is already using the NFS port.
```bash
# Find and kill existing rclone mount
pgrep -fl "rclone.*nfsmount"
kill <pid>
# Or force unmount first
diskutil unmount force /Volumes/keymaging
```

#### "mount helper error" (FUSE mount)
macFUSE not installed or not loaded. Use `nfsmount` instead:
```bash
rclone nfsmount remote: /mount/point --vfs-cache-mode full
```

### Mount is unstable / disconnects

1. **Check network:** `ping 1.1.1.1`
2. **Check logs:** `tail -f ~/Library/Logs/rclone-keymaging.log`
3. **Check LaunchAgent:** `launchctl list | grep rclone`
4. **Restart mount:**
   ```bash
   launchctl bootout gui/$(id -u)/com.rclone.keymaging
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
   ```

### Mount performance is poor

- Increase `--vfs-cache-max-size` (e.g., `20G`)
- Increase `--dir-cache-time` (e.g., `30m`)
- Decrease `--poll-interval` if remote changes rarely (e.g., `5m`)
- Use `--vfs-cache-mode full` for read-heavy workloads
- Ensure `--nfs-cache-type disk` for persistent NFS handles

### Finder shows "Operation not permitted"
VFS cache may be stale. Force refresh:
```bash
# Clear VFS cache for a remote
rm -rf ~/.cache/rclone/vfs/keymaging/

# Restart mount
launchctl bootout gui/$(id -u)/com.rclone.keymaging
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
```

## LaunchAgent Issues (macOS)

### Agent not running
```bash
# Check status
launchctl list | grep rclone

# If not listed, bootstrap it
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist

# If shows error code, check logs
tail -50 ~/Library/Logs/rclone-keymaging.log
```

### Agent exits immediately (exit code 78)
Configuration error. Common causes:
- Config password not available (Keychain issue)
- Remote name typo in plist
- Mount point doesn't exist

### Agent keeps restarting
`KeepAlive` is `true` — rclone restarts on crash. Check logs for the crash reason:
```bash
tail -100 ~/Library/Logs/rclone-keymaging.log | grep -i "error\|fatal\|panic"
```

### Reload after plist change
```bash
launchctl bootout gui/$(id -u)/com.rclone.keymaging
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
```

### Agent doesn't start at login
- Verify plist is in `~/Library/LaunchAgents/` (not `/Library/LaunchAgents/`)
- Check `RunAtLoad` is `<true/>` in plist
- Check plist is valid: `plutil -lint ~/Library/LaunchAgents/com.rclone.keymaging.plist`

## VFS Cache Issues

### Cache corruption
Symptoms: stale files, read errors, apps see wrong data.
```bash
# Stop mount
launchctl bootout gui/$(id -u)/com.rclone.keymaging

# Clear cache
rm -rf ~/.cache/rclone/vfs/keymaging/

# Restart
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
```

### Cache growing too large
```bash
# Check cache size
du -sh ~/.cache/rclone/vfs/

# Reduce limits in LaunchAgent plist
--vfs-cache-max-size 5G    # Lower max size
--vfs-cache-max-age 24h    # Shorter retention
```

### Write-back failures
If VFS cache has pending writes that fail to upload:
```bash
# Check for pending writes
ls -la ~/.cache/rclone/vfs/keymaging/

# Force write-back
rclone rc vfs/refresh --fast-list  # if rc is enabled
```

## Rate Limiting

### OneDrive: 429 Too Many Requests
- rclone auto-retries with exponential backoff
- Reduce `--transfers` to 2-3
- Add `--tpslimit 2`
- SharePoint has stricter limits than personal OneDrive

### Google Drive: "userRateLimitExceeded"
- Use custom Client ID
- Reduce `--transfers` and `--checkers`
- Add `--tpslimit 2 --tpslimit-burst 5`
- Wait for quota reset (per-minute and per-day quotas)

## Recovery Procedures

### Recover from bad sync
If `rclone sync` deleted files it shouldn't have:
1. Check OneDrive/Google Drive recycle bin (files recoverable for 93/30 days)
2. Use `--backup-dir` flag in future syncs to keep deleted files locally
3. If using bisync: check `.rclone/bisync/` for conflict files

### Recover from corrupt config
```bash
# Backup current config
cp ~/.config/rclone/rclone.conf ~/.config/rclone/rclone.conf.bak

# Start fresh
rclone config  # Reconfigure remotes
```

### Recover from stuck mount
```bash
# Force unmount
diskutil unmount force /Volumes/keymaging

# Kill rclone processes
pkill -f "rclone.*nfsmount"

# Clean up mount point
sudo rmdir /Volumes/keymaging
sudo mkdir /Volumes/keymaging
sudo chown "$USER" /Volumes/keymaging

# Restart
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist
```

## Diagnostic Commands

```bash
# Full diagnostic info
rclone version --check                 # Check for updates
rclone config show                     # Dump config (decrypted)
rclone listremotes                     # List all remotes
rclone about remote:                   # Quota/usage
rclone lsd remote: --max-depth 1       # Quick connectivity test
rclone rc core/stats                   # Runtime stats (if rc enabled)

# System checks
mount | grep rclone                    # Check mounts
launchctl list | grep rclone           # Check agents
pgrep -fl rclone                       # Running processes
du -sh ~/.cache/rclone/                # Cache size
tail -f ~/Library/Logs/rclone-*.log    # Live logs
```
