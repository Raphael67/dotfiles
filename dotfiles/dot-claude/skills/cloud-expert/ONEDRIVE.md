# OneDrive Backend Reference

## Authentication

### OAuth 2.0 via Microsoft Graph
- rclone uses Microsoft Graph API with OAuth 2.0 authorization code flow
- Default: uses rclone's shared client ID (rate-limited across all users)
- Custom client ID: register an Azure AD app for better rate limits
- Token stored in `rclone.conf` as JSON blob with `access_token` and `refresh_token`

### Token Refresh
- Access tokens expire after ~1 hour, auto-refreshed via refresh token
- Refresh tokens expire after **90 days of inactivity** — use remotes regularly or run `rclone reconnect remote:`
- If token expires: `rclone config reconnect remote-name` to re-authorize

### Custom Client ID Setup
1. Register app at https://portal.azure.com → App registrations
2. Redirect URI: `http://localhost:53682/`
3. API permissions: `Files.Read`, `Files.ReadWrite`, `Files.Read.All`, `Files.ReadWrite.All`, `Sites.Read.All`, `offline_access`
4. Create client secret
5. Use in rclone config: `client_id` and `client_secret`

## Remote Types

### Personal OneDrive / OneDrive for Business
```ini
[onedrive-personal]
type = onedrive
token = {"access_token":"...","refresh_token":"...","expiry":"..."}
drive_id = <auto-detected>
drive_type = business  # or "personal"
```

During `rclone config`:
- Choose "OneDrive Personal or Business"
- Select drive type: `personal` or `business`

### SharePoint Document Libraries
```ini
[sp-library-name]
type = onedrive
token = {"access_token":"...","refresh_token":"...","expiry":"..."}
drive_id = <sharepoint-drive-id>
drive_type = documentLibrary
```

During `rclone config`:
- Choose "Search for a SharePoint site"
- Or specify site URL directly
- Select the document library

### SharePoint Site Discovery
Programmatic discovery via Microsoft Graph API:

```bash
# List all sites
GET https://graph.microsoft.com/v1.0/sites?search=*&$top=100

# List drives for a site
GET https://graph.microsoft.com/v1.0/sites/{site-id}/drives

# Each drive has an 'id' → use as drive_id in rclone config
```

Token can be reused from an existing OneDrive remote (`rclone config show remote-name` → extract token JSON).

### drive_id Handling
- Auto-detected for Personal/Business during interactive config
- Must be manually specified for SharePoint libraries
- Format: long hex string like `b!abc123...`
- Can create remotes non-interactively: `rclone config create name onedrive token "$TOKEN" drive_id "$ID" drive_type documentLibrary`

## Performance Flags

| Flag | Purpose |
|------|---------|
| `--onedrive-delta` | Use delta queries for fast incremental listing |
| `--onedrive-no-versions` | Disable version cleanup (faster sync) |
| `--fast-list` | Use recursive listing API (fewer API calls) |

### Delta Queries
`--onedrive-delta` uses Microsoft Graph delta API to get only changed files since last check. Significantly faster for large libraries with few changes.

## SharePoint Quirks

### Silent Modification
SharePoint may silently modify uploaded files (e.g., stripping metadata from Office docs). This causes hash mismatches on next sync.

### Sync Loops
If SharePoint modifies files on upload, `rclone sync` sees them as changed → re-uploads → SharePoint modifies again → infinite loop.

**Workaround:** Use `--ignore-size` and `--checksum` to break the cycle, or `--ignore-checksum` with `--size-only`.

### Path Limitations
- Max file size: **250 GiB**
- Max path length: **400 characters** (including remote prefix)
- Case-insensitive file system
- Forbidden characters: `\ : * ? " < > |` and names ending in space/period

### Site Naming
SharePoint site names may contain non-ASCII characters. rclone config handles this, but scripts should sanitize names for remote identifiers.

## Microsoft Graph API

### Key Endpoints
| Endpoint | Purpose |
|----------|---------|
| `GET /me/drive` | Current user's OneDrive |
| `GET /me/drive/root/children` | List root items |
| `GET /sites?search=*` | List all SharePoint sites |
| `GET /sites/{id}/drives` | List document libraries for site |
| `GET /drives/{id}/root/children` | List root of a drive |
| `PUT /drives/{id}/items/{parent-id}:/{filename}:/content` | Upload file |

### Rate Limits
- Microsoft Graph: 10,000 requests per 10 minutes per app per tenant
- OneDrive: Additional per-user throttling (429 responses)
- SharePoint: Stricter limits, especially on bulk operations
- Use `--tpslimit` to cap requests per second if hitting limits

### Permissions
| Permission | Scope |
|------------|-------|
| `Files.Read` | Read user's files |
| `Files.ReadWrite` | Read/write user's files |
| `Files.Read.All` | Read all files user can access |
| `Files.ReadWrite.All` | Read/write all files user can access |
| `Sites.Read.All` | Read all SharePoint sites (needed for discovery) |
| `offline_access` | Refresh tokens (required) |

## macOS Native OneDrive Client

The native OneDrive sync client on macOS uses Files On-Demand (cloud-only files). Conflicts with rclone if both point to the same OneDrive:
- Don't mount the same path with both rclone and the native client
- Use rclone for server-side operations (SharePoint, automation)
- Use native client for desktop integration (Finder, Office co-authoring)
