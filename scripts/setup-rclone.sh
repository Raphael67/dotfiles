#!/usr/bin/env bash
# Setup script for rclone OneDrive mounts
# Run this once after stowing dotfiles to configure remotes and mounts.
#
# Architecture:
#   - onedrive-personal: remote -> Personal OneDrive (business)
#   - onedrive-shared: remote -> SharePoint root site
#   - sp-*: remotes -> individual SharePoint document libraries
#   - keymaging: combine remote -> merges all above into one mount
#   - /Volumes/keymaging -> single NFS mount point

set -euo pipefail

BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; }
step()  { echo -e "\n${BOLD}==> Step $1: $2${NC}"; }

# Pre-flight checks
if ! command -v rclone &>/dev/null; then
    error "rclone not found. Install via: brew install rclone"
    exit 1
fi
if ! command -v python3 &>/dev/null; then
    error "python3 not found"
    exit 1
fi

echo -e "${BOLD}rclone OneDrive Setup${NC}"
echo "Mounts OneDrive Personal + all SharePoint libraries under /Volumes/keymaging"
echo ""

# Step 1: Configure base remotes
step 1 "Configure OneDrive remotes"
echo "You need to create two remotes via 'rclone config':"
echo "  1. onedrive-personal  - Your OneDrive for Business"
echo "  2. onedrive-shared    - SharePoint root site (for token reuse)"
echo ""
echo "For each remote:"
echo "  - Type: onedrive"
echo "  - Leave client_id, client_secret, tenant blank"
echo "  - Follow the browser OAuth flow"
echo "  - onedrive-personal: choose 'OneDrive Personal or Business', drive type 'business'"
echo "  - onedrive-shared: choose 'Search for a Sharepoint site', search your org name"
echo ""
read -rp "Press Enter to open 'rclone config' (or Ctrl+C to skip)..."
rclone config

# Step 2: Encrypt config
step 2 "Set config encryption password"
echo "Encrypt rclone.conf so OAuth tokens aren't stored in plaintext."
echo "In the config menu: choose 's) Set configuration password'"
echo ""
read -rp "Press Enter to open 'rclone config' for encryption setup..."
rclone config

# Step 3: Store password in Keychain
step 3 "Store encryption password in macOS Keychain"
echo "This stores the config password so the LaunchAgent can decrypt it."
echo ""
read -rsp "Enter the rclone config password you just set: " RCLONE_PASS
echo ""

if security find-generic-password -a rclone -s rclone-config &>/dev/null; then
    warn "Keychain entry already exists. Updating..."
    security delete-generic-password -a rclone -s rclone-config &>/dev/null || true
fi

security add-generic-password -a rclone -s rclone-config -w "$RCLONE_PASS"
info "Password stored in Keychain (account: rclone, service: rclone-config)"
unset RCLONE_PASS

# Step 4: Verify config decryption
step 4 "Verify config decryption"
export RCLONE_PASSWORD_COMMAND="security find-generic-password -a rclone -s rclone-config -w"

if rclone listremotes | grep -q "onedrive-personal:"; then
    info "onedrive-personal remote found"
else
    warn "onedrive-personal remote not found - check rclone config"
fi

if rclone listremotes | grep -q "onedrive-shared:"; then
    info "onedrive-shared remote found"
else
    warn "onedrive-shared remote not found - check rclone config"
fi

# Step 5: Create SharePoint library remotes
step 5 "Create SharePoint library remotes"
echo "Discovering all SharePoint sites and document libraries..."
echo "This reuses the onedrive-shared token to create individual remotes."
echo ""

python3 << 'PYEOF'
import json, os, subprocess, urllib.request, re

env = {**os.environ, 'RCLONE_PASSWORD_COMMAND': 'security find-generic-password -a rclone -s rclone-config -w'}

# Get token from onedrive-shared
result = subprocess.run(['rclone', 'config', 'show', 'onedrive-shared'], capture_output=True, text=True, env=env)
token_line = [l for l in result.stdout.split('\n') if l.strip().startswith('token =')][0]
token_str = token_line.split('token = ', 1)[1]
token_data = json.loads(token_str)
access_token = token_data['access_token']

# Get existing remotes to skip
result = subprocess.run(['rclone', 'listremotes'], capture_output=True, text=True, env=env)
existing = set(r.rstrip(':') for r in result.stdout.strip().split('\n'))

# Get all SharePoint sites
req = urllib.request.Request(
    'https://graph.microsoft.com/v1.0/sites?search=*&$top=100',
    headers={'Authorization': f'Bearer {access_token}'}
)
data = json.loads(urllib.request.urlopen(req).read())

skip_names = {'Site Racine', "Site d'équipe", 'Site hub de pointpublishing', 'Apps', 'Designer', 'Admins Git'}
skip_urls = {'contentstorage', 'portals', 'appcatalog', 'contentTypeHub'}

sites = [s for s in data.get('value', [])
         if s.get('displayName', '') not in skip_names
         and not any(sk in s.get('webUrl', '') for sk in skip_urls)]

# Collect all document libraries
libraries = []
for site in sites:
    site_name = site.get('displayName', 'Unknown')
    req = urllib.request.Request(
        f"https://graph.microsoft.com/v1.0/sites/{site['id']}/drives",
        headers={'Authorization': f'Bearer {access_token}'}
    )
    try:
        drives = json.loads(urllib.request.urlopen(req).read()).get('value', [])
        for drive in drives:
            if drive['name'] == 'Teams Wiki Data':
                continue
            safe = re.sub(r'[^a-zA-Z0-9-]', '-', f"{site_name} - {drive['name']}".lower())
            safe = re.sub(r'-+', '-', safe).strip('-')
            libraries.append({
                'remote_name': f"sp-{safe}",
                'drive_id': drive['id'],
            })
    except:
        pass

# Deduplicate remote names
seen = {}
for lib in libraries:
    name = lib['remote_name']
    if name in seen:
        seen[name] += 1
        lib['remote_name'] = f"{name}-{seen[name]}"
    else:
        seen[name] = 1

# Create missing remotes (--non-interactive avoids OAuth trigger)
created, skipped = 0, 0
for lib in libraries:
    if lib['remote_name'] in existing:
        skipped += 1
        continue
    result = subprocess.run([
        'rclone', 'config', 'create', '--non-interactive',
        lib['remote_name'], 'onedrive',
        'token', token_str,
        'drive_id', lib['drive_id'],
        'drive_type', 'documentLibrary',
    ], capture_output=True, text=True, env=env)
    if result.returncode == 0:
        created += 1
    else:
        print(f"  FAIL: {lib['remote_name']}")

print(f"  Created {created} new remotes, skipped {skipped} existing")

# Build combine remote: Personal + all sp- remotes
result = subprocess.run(['rclone', 'listremotes'], capture_output=True, text=True, env=env)
sp_remotes = sorted([r.rstrip(':') for r in result.stdout.strip().split('\n') if r.startswith('sp-')])

# Exclude patterns from combine mount (remotes still exist but aren't mounted)
import re as _re
exclude_patterns = [r'^sp-contenus-', r'^sp-corpo-', r'^sp-edf-']
sp_remotes = [r for r in sp_remotes if not any(_re.match(p, r) for p in exclude_patterns)]

parts = ['Personal=onedrive-personal:']
for r in sp_remotes:
    parts.append(f"{r[3:]}={r}:")
upstreams = ' '.join(parts)

subprocess.run(['rclone', 'config', 'create', '--non-interactive', 'keymaging', 'combine', 'upstreams', upstreams],
              capture_output=True, text=True, env=env)
# Also try update in case it already exists
subprocess.run(['rclone', 'config', 'update', 'keymaging', 'upstreams', upstreams],
              capture_output=True, text=True, env=env)

print(f"  Combine remote 'keymaging' configured with {len(parts)} upstreams")
PYEOF

# Step 6: Create mount point
step 6 "Create mount point"
if [[ -d "/Volumes/keymaging" ]]; then
    info "/Volumes/keymaging already exists"
else
    info "Creating /Volumes/keymaging (requires sudo)..."
    sudo mkdir -p /Volumes/keymaging
    sudo chown "$USER" /Volumes/keymaging
fi

# Step 7: Test
step 7 "Test remote access"
echo "Listing keymaging: combine remote..."
if rclone lsd keymaging: --max-depth 1 2>/dev/null | head -10; then
    info "keymaging: remote is accessible"
else
    warn "keymaging: could not list - check config"
fi

# Step 8: Load LaunchAgent
step 8 "Load LaunchAgent"
echo "This will mount /Volumes/keymaging with all OneDrive + SharePoint folders."
echo "Note: first mount takes ~15 seconds with many SharePoint libraries."
echo ""
read -rp "Load LaunchAgent now? [y/N] " reply
if [[ "$reply" =~ ^[Yy]$ ]]; then
    plist=~/Library/LaunchAgents/com.rclone.keymaging.plist
    if [[ -f "$plist" ]]; then
        launchctl bootout "gui/$(id -u)/com.rclone.keymaging" 2>/dev/null || true
        launchctl bootstrap "gui/$(id -u)" "$plist"
        info "Loaded com.rclone.keymaging"
    else
        warn "Plist not found at $plist - run 'stow .' first"
    fi

    echo ""
    echo "Waiting for mount (this may take ~15 seconds)..."
    for i in $(seq 1 30); do
        if mount | grep -q "/Volumes/keymaging"; then
            info "/Volumes/keymaging is mounted"
            break
        fi
        sleep 1
    done

    if ! mount | grep -q "/Volumes/keymaging"; then
        warn "Mount not yet visible - check: tail -f ~/Library/Logs/rclone-keymaging.log"
    fi
else
    echo "Skipped. Load manually with:"
    echo "  launchctl bootstrap gui/\$(id -u) ~/Library/LaunchAgents/com.rclone.keymaging.plist"
fi

echo ""
info "Setup complete!"
echo ""
echo "Mount point: /Volumes/keymaging"
echo "  Personal/              - Your OneDrive"
echo "  bizdev-clients/        - SharePoint: BizDev - Clients"
echo "  communication-mailing/ - SharePoint: Communication - Mailing"
echo "  ...                    - (all other SharePoint libraries)"
echo ""
echo "Useful commands:"
echo "  rclone lsd keymaging:             # List all folders"
echo "  rclone about onedrive-personal:   # Show quota/usage"
echo "  launchctl list | grep rclone      # Check service status"
echo "  tail -f ~/Library/Logs/rclone-keymaging.log  # Watch logs"
