# Nushell Environment Configuration

# XDG Base Directories
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")
$env.XDG_STATE_HOME = ($env.HOME | path join ".local" "state")

# Homebrew (macOS)
if ("/opt/homebrew/bin" | path exists) {
    $env.PATH = ($env.PATH | prepend "/opt/homebrew/bin")
    $env.PATH = ($env.PATH | prepend "/opt/homebrew/sbin")
}

# Editor
$env.EDITOR = "nvim"
$env.VISUAL = "nvim"

# PATH additions
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".local" "bin"))
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".cargo" "bin"))
$env.PATH = ($env.PATH | prepend ($env.HOME | path join ".bun" "bin"))

# Starship prompt
if (which starship | is-not-empty) {
    $env.STARSHIP_CONFIG = ($env.HOME | path join ".config" "starship" "starship.toml")

    mkdir ($nu.default-config-dir | path join "vendor" "autoload")
    starship init nu | save -f ($nu.default-config-dir | path join "vendor" "autoload" "starship.nu")
}

# Zoxide
if (which zoxide | is-not-empty) {
    zoxide init nushell | save -f ($nu.default-config-dir | path join "vendor" "autoload" "zoxide.nu")
}
