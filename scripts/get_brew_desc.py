import subprocess
import json
import sys

formulae = [
    "automake", "bison", "bitwarden-cli", "btop", "chafa", "cinecli", "cmake-docs", 
    "detect-secrets", "doxx", "dtc", "e2fsprogs", "fcoury/tap/tsql", "gdbm", 
    "gemini-cli", "git-filter-repo", "glab", "gromgit/fuse/ext4fuse-mac", "jira-cli", 
    "k9s", "libffi", "libyaml", "mas", "mprocs", "node@24", "nvm", "ollama", 
    "openjdk@17", "openssl@3", "pipx", "python@3.12", "rclone", "readline", 
    "rustup", "superstarryeyes/tap/hys", "tesseract-lang", "u-boot-tools", "uv", 
    "viu", "w3m", "watch", "watchman", "woff2", "xz", "yt-dlp"
]

casks = [
    "discord", "firefox", "firefox@developer-edition", "lens", "libreoffice", 
    "macfuse", "microsoft-auto-update", "postman", "pycharm-ce", "sourcetree", 
    "stats", "wezterm"
]

all_packages = formulae + casks

def get_info(packages):
    try:
        # Run brew info --json=v2
        cmd = ["brew", "info", "--json=v2"] + packages
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Error running brew info: {e}", file=sys.stderr)
        return None

data = get_info(all_packages)

if data:
    print("### Formulae")
    
    # Create a lookup dictionary
    lookup = {}
    for f in data.get('formulae', []):
        lookup[f['name']] = f['desc']
        lookup[f['full_name']] = f['desc'] # handle tap/package format
    
    for pkg in formulae:
        desc = lookup.get(pkg, "No description found")
        print(f"* **{pkg}**: {desc}")

    print("")
    print("### Casks")
    cask_map = {}
    for c in data.get('casks', []):
        desc = c.get('desc')
        if not desc and c.get('name'):
             desc = ", ".join(c['name'])
        cask_map[c['token']] = desc
    
    for pkg in casks:
        desc = cask_map.get(pkg, "No description found")
        print(f"* **{pkg}**: {desc}")