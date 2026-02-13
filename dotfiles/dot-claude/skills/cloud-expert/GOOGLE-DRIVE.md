# Google Drive Backend Reference

## Authentication

### OAuth 2.0
- rclone uses OAuth 2.0 authorization code flow via Google APIs
- Default: rclone's shared client ID (shared rate limits)
- **Strongly recommended:** Create your own Client ID for better rate limits

### Service Account
- For server-to-server access without browser OAuth
- Create in Google Cloud Console → IAM → Service Accounts
- Download JSON key file
- Use: `rclone config create gdrive drive service_account_file /path/to/key.json`
- Must share target folders/drives with service account email

### OAuth Scopes
| Scope | Flag | Access |
|-------|------|--------|
| `drive` | (default) | Full access to all files |
| `drive.readonly` | `--drive-scope drive.readonly` | Read-only access |
| `drive.file` | `--drive-scope drive.file` | Only files created by rclone |
| `drive.appfolder` | `--drive-scope drive.appfolder` | App-specific folder only |
| `drive.metadata.readonly` | `--drive-scope drive.metadata.readonly` | Metadata only |

### Custom Client ID Setup
1. Go to https://console.cloud.google.com/
2. Create project → Enable Google Drive API
3. OAuth consent screen → External → Add scopes (`../auth/drive`)
4. Credentials → Create OAuth Client ID → Desktop app
5. Note Client ID and Client Secret
6. Use in `rclone config`: set `client_id` and `client_secret`

**Why custom ID matters:** rclone's shared client ID is rate-limited across all rclone users globally. A personal client ID gets your own quota.

## Rate Limits

| Limit | Value |
|-------|-------|
| Upload | ~750 GiB per day per user |
| Download | ~10 TiB per day per user |
| API queries | ~10 queries/sec per user, ~2 files/sec effective |
| File creation | ~2 files/sec |
| Shared Drive | ~20,000 files per folder |

### Handling Rate Limits
```bash
# Limit API calls
--tpslimit 2            # Max 2 transactions/sec
--tpslimit-burst 5      # Allow bursts up to 5

# Limit bandwidth
--bwlimit 100M          # 100 MB/s max

# Reduce concurrent operations
--transfers 2            # Fewer parallel transfers
--checkers 4             # Fewer parallel checkers
```

### Error 403: Rate Limit Exceeded
- Wait and retry (rclone auto-retries with backoff)
- Reduce `--transfers` and `--tpslimit`
- Switch to custom Client ID if using shared

## Performance

### --fast-list
**Essential for Google Drive.** Uses the `files.list` API with recursive traversal instead of per-folder listing. **Up to 20x faster** for large drives.

```bash
rclone ls gdrive: --fast-list
```

Without `--fast-list`, rclone makes one API call per directory. With it, a single recursive call fetches the entire tree.

### Chunk Size
```bash
--drive-chunk-size 64M   # Upload chunk size (default 8M)
```
Larger chunks = fewer API calls for big files, but more memory. Increase for large file uploads.

## Duplicate Handling

Google Drive allows multiple files with the same name in the same folder. This is a common issue.

```bash
# Find duplicates
rclone dedupe --dedupe-mode list gdrive:path

# Remove duplicates (keep newest)
rclone dedupe --dedupe-mode newest gdrive:path

# Interactive dedup
rclone dedupe --dedupe-mode interactive gdrive:path
```

Modes: `newest`, `oldest`, `largest`, `smallest`, `first`, `rename`

## Google Docs Export

Google Docs/Sheets/Slides are not real files — they're cloud-native. rclone exports them on download.

### Export Formats
```ini
[gdrive]
type = drive
export_formats = docx,xlsx,pptx,svg
import_formats = docx,xlsx,pptx
```

| Google Type | Default Export | Alternatives |
|-------------|--------------|--------------|
| Docs | `.docx` | `.pdf`, `.odt`, `.txt`, `.html` |
| Sheets | `.xlsx` | `.pdf`, `.ods`, `.csv`, `.tsv` |
| Slides | `.pptx` | `.pdf`, `.odp` |
| Drawings | `.svg` | `.pdf`, `.png`, `.jpg` |

### Skip Google Docs
```bash
--drive-skip-gdocs    # Don't download Google Docs at all
```

## Shared Drives (Team Drives)

### Setup
```bash
rclone config create teamdrive drive \
  team_drive <drive-id> \
  scope drive
```

During interactive config: select "Shared Drive" and pick from list.

### Key Differences
- Shared Drives have a 400,000 item limit
- Max 20,000 items per folder
- Ownership is by the drive, not individuals
- Different permission model (no "anyone with link" by default)
- `--drive-shared-with-me` to list files shared with you (not in Shared Drives)

## Google Drive API

### Key Endpoints
| Endpoint | Purpose |
|----------|---------|
| `GET /drive/v3/files` | List files |
| `GET /drive/v3/files/{id}` | Get file metadata |
| `POST /upload/drive/v3/files` | Upload file |
| `GET /drive/v3/drives` | List Shared Drives |
| `GET /drive/v3/files/{id}/export` | Export Google Doc |

### Useful API Parameters
- `q`: Search query (e.g., `name = 'file.txt'`)
- `fields`: Limit returned fields (reduces response size)
- `pageSize`: Items per page (max 1000)
- `orderBy`: Sort results

## Limitations

| Limit | Value |
|-------|-------|
| Max file size | 5 TiB |
| Max path depth | No hard limit (but UI breaks at ~20 levels) |
| File name max | 255 characters |
| Forbidden characters | `NUL`, `/` |
| Case sensitivity | Preserves case but matches case-insensitively in search |
| Trash | Files go to trash on delete (30-day auto-purge) |
