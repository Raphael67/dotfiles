# rclone Core Reference

## Installation

### Homebrew (recommended on macOS)
```bash
brew install rclone
```

### Binary Install
```bash
curl https://rclone.org/install.sh | sudo bash
```

### Homebrew Mount Limitation
Homebrew-installed rclone **cannot use FUSE mounts** (`rclone mount`) on macOS because macFUSE requires a kernel extension. Use `rclone nfsmount` instead — it works without FUSE and is the recommended approach on macOS.

## Config File

### Location
- Default: `~/.config/rclone/rclone.conf`
- Override: `RCLONE_CONFIG` env var or `--config` flag

### Encryption
rclone supports encrypting `rclone.conf` with a password (uses NaCl secretbox, indicated by `RCLONE_ENCRYPT_V0` header).

```bash
# Set/change password
rclone config  # → 's) Set configuration password'

# Decrypt at runtime
export RCLONE_PASSWORD_COMMAND="security find-generic-password -a rclone -s rclone-config -w"
# or
export RCLONE_CONFIG_PASS="yourpassword"  # less secure
```

When encrypted, all `rclone` commands require the password to read config. `RCLONE_PASSWORD_COMMAND` runs a shell command to retrieve it (e.g., from macOS Keychain).

## Core Commands

### sync
```bash
rclone sync source:path dest:path [flags]
```
One-way sync: makes dest identical to source. **Deletes files in dest not in source.** Always use `--dry-run` first.

Key flags: `--dry-run`, `--max-delete`, `--backup-dir`, `--suffix`

### copy
```bash
rclone copy source:path dest:path [flags]
```
Copy files from source to dest. **Does not delete anything.** Safe default choice.

### move
```bash
rclone move source:path dest:path [flags]
```
Move files: copies then deletes from source. Use `--delete-empty-src-dirs` to clean up.

### bisync
```bash
rclone bisync path1 path2 [flags]
```
Two-way sync. Requires `--resync` on first run to establish baseline. More complex conflict handling than one-way sync.

Key flags: `--resync` (first run), `--force` (override safety), `--check-access`

### mount
```bash
rclone mount remote:path /local/mountpoint [flags]
```
FUSE mount. Requires macFUSE on macOS (kernel extension). **Not recommended on macOS** — use `nfsmount` instead.

### nfsmount
```bash
rclone nfsmount remote:path /local/mountpoint [flags]
```
NFS-based mount. **Recommended on macOS.** No FUSE dependency. Uses kernel NFS client. Same VFS layer as `mount`.

Key flags: `--nfs-cache-type disk` (persist NFS handles across restarts)

### serve
```bash
rclone serve webdav remote:path [flags]
rclone serve http remote:path [flags]
rclone serve ftp remote:path [flags]
```
Serve a remote over various protocols. Useful for local network access.

### check
```bash
rclone check source:path dest:path [flags]
```
Compare source and dest without transferring. Reports missing and changed files.

Key flags: `--checksum` (compare hashes), `--download` (verify by downloading)

### dedupe
```bash
rclone dedupe remote:path [flags]
```
Find and remove duplicate files. Interactive by default. **Destructive — back up first.**

Modes: `--dedupe-mode newest|oldest|largest|smallest|first|rename`

## Critical Flags

### Safety
| Flag | Purpose |
|------|---------|
| `--dry-run` / `-n` | Preview changes without executing |
| `--interactive` / `-i` | Confirm each operation |
| `--max-delete N` | Abort if more than N deletions (use `N%` for percentage) |
| `--backup-dir path` | Move deleted/replaced files here instead of deleting |

### Performance
| Flag | Purpose |
|------|---------|
| `--fast-list` | Use fewer API calls for listing (essential for large remotes) |
| `--transfers N` | Number of parallel file transfers (default 4) |
| `--checkers N` | Number of parallel hash checkers (default 8) |
| `--bwlimit RATE` | Bandwidth limit (e.g., `10M`, `1G`, off-peak: `08:00,512k 00:00,off`) |
| `--buffer-size SIZE` | In-memory buffer per transfer (default 16M) |
| `--multi-thread-streams N` | Split large files into N parallel downloads |

### Verification
| Flag | Purpose |
|------|---------|
| `--checksum` | Compare by hash instead of size+modtime |
| `--size-only` | Compare by size only (faster, less accurate) |
| `--ignore-size` | Ignore size differences |
| `--progress` / `-P` | Show real-time transfer progress |

## VFS Cache Modes

Used with `mount`/`nfsmount` to control local caching behavior.

| Mode | Flag | Behavior |
|------|------|----------|
| Off | `--vfs-cache-mode off` | No caching. Reads/writes go direct to remote. Fastest for sequential access. |
| Minimal | `--vfs-cache-mode minimal` | Cache only opens for read, write through. |
| Writes | `--vfs-cache-mode writes` | Cache files opened for writing. Reads still direct. |
| Full | `--vfs-cache-mode full` | Cache all reads and writes locally. **Required for most applications.** |

### VFS Tuning Flags
| Flag | Default | Purpose |
|------|---------|---------|
| `--vfs-cache-max-size` | off | Max total cache size (e.g., `10G`) |
| `--vfs-cache-max-age` | 1h | Max time to keep cached files (e.g., `72h`) |
| `--vfs-cache-poll-interval` | 1m | How often to check for stale cache |
| `--vfs-read-chunk-size` | 128M | Initial read chunk (increases with `--vfs-read-chunk-size-limit`) |
| `--vfs-write-back` | 5s | Delay before writing back to remote |
| `--vfs-refresh` | false | Refresh directory listings from remote |
| `--dir-cache-time` | 5m | How long to cache directory listings |
| `--poll-interval` | 1m | Poll remote for changes |

### VFS Cache Location
- Default: `~/.cache/rclone/vfs/<remote-name>/`
- Override: `--cache-dir`
- **Monitor size** — can grow large with `full` mode

## Filtering

### Include/Exclude
```bash
# Include only certain patterns
rclone sync src: dst: --include "*.pdf" --include "*.docx"

# Exclude patterns
rclone sync src: dst: --exclude "*.tmp" --exclude ".DS_Store"

# Filter from file
rclone sync src: dst: --filter-from rules.txt
```

### Filter File Syntax
```
+ *.pdf          # include
- *.tmp          # exclude
- .DS_Store
+ Documents/**   # include directory tree
- *              # exclude everything else
```

### Size and Age Filters
```bash
--min-size 1M          # Skip files smaller than 1MB
--max-size 10G         # Skip files larger than 10GB
--min-age 1d           # Skip files newer than 1 day
--max-age 30d          # Skip files older than 30 days
```

## Remote Types

| Type | Config Type | Purpose |
|------|-------------|---------|
| `onedrive` | onedrive | OneDrive Personal/Business/SharePoint |
| `drive` | drive | Google Drive |
| `iclouddrive` | iclouddrive | iCloud Drive (experimental) |
| `combine` | combine | Merge multiple remotes into one |
| `crypt` | crypt | Encrypt/decrypt wrapper |
| `union` | union | Overlay multiple remotes (read from first match) |
| `alias` | alias | Rename/repoint a remote |
| `s3` | s3 | Amazon S3 and compatible |
| `b2` | b2 | Backblaze B2 |
| `sftp` | sftp | SFTP/SSH |

## Logging and Debugging

### Log Levels
| Level | Flag | Shows |
|-------|------|-------|
| ERROR | `--log-level ERROR` | Errors only |
| NOTICE | `--log-level NOTICE` | Normal operations (default) |
| INFO | `--log-level INFO` | Informational messages |
| DEBUG | `--log-level DEBUG` | Full debug output (verbose) |

### Flags
```bash
--log-file /path/to/log.txt   # Log to file
--verbose / -v                  # INFO level
--verbose --verbose / -vv       # DEBUG level
--dump headers                  # Dump HTTP headers
--dump bodies                   # Dump HTTP bodies (very verbose)
--dump requests                 # Dump HTTP request/response
```

### Useful Debug Commands
```bash
# Test remote connectivity
rclone lsd remote: --max-depth 1

# Check config is valid
rclone config show remote-name

# List all remotes
rclone listremotes

# Show remote quota
rclone about remote:

# Show file hashes
rclone hashsum md5 remote:path
```
