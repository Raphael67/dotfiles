# Nushell Configuration

# Theme: Catppuccin Macchiato
let catppuccin_macchiato = {
    rosewater: "#f4dbd6"
    flamingo: "#f0c6c6"
    pink: "#f5bde6"
    mauve: "#c6a0f6"
    red: "#ed8796"
    maroon: "#ee99a0"
    peach: "#f5a97f"
    yellow: "#eed49f"
    green: "#a6da95"
    teal: "#8bd5ca"
    sky: "#91d7e3"
    sapphire: "#7dc4e4"
    blue: "#8aadf4"
    lavender: "#b7bdf8"
    text: "#cad3f5"
    subtext1: "#b8c0e0"
    subtext0: "#a5adcb"
    overlay2: "#939ab7"
    overlay1: "#8087a2"
    overlay0: "#6e738d"
    surface2: "#5b6078"
    surface1: "#494d64"
    surface0: "#363a4f"
    base: "#24273a"
    mantle: "#1e2030"
    crust: "#181926"
}

$env.config.color_config = {
    separator: $catppuccin_macchiato.overlay0
    leading_trailing_space_bg: { attr: "n" }
    header: { fg: $catppuccin_macchiato.blue attr: "b" }
    empty: $catppuccin_macchiato.lavender
    bool: $catppuccin_macchiato.lavender
    int: $catppuccin_macchiato.peach
    filesize: $catppuccin_macchiato.teal
    duration: $catppuccin_macchiato.teal
    date: $catppuccin_macchiato.mauve
    range: $catppuccin_macchiato.peach
    float: $catppuccin_macchiato.peach
    string: $catppuccin_macchiato.green
    nothing: $catppuccin_macchiato.red
    binary: $catppuccin_macchiato.peach
    cell_path: $catppuccin_macchiato.peach
    row_index: { fg: $catppuccin_macchiato.mauve attr: "b" }
    record: $catppuccin_macchiato.lavender
    list: $catppuccin_macchiato.lavender
    block: $catppuccin_macchiato.lavender
    hints: $catppuccin_macchiato.overlay1
    shape_and: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_binary: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_block: { fg: $catppuccin_macchiato.blue attr: "b" }
    shape_bool: $catppuccin_macchiato.teal
    shape_custom: $catppuccin_macchiato.green
    shape_datetime: { fg: $catppuccin_macchiato.teal attr: "b" }
    shape_directory: $catppuccin_macchiato.teal
    shape_external: $catppuccin_macchiato.teal
    shape_externalarg: { fg: $catppuccin_macchiato.green attr: "b" }
    shape_filepath: $catppuccin_macchiato.teal
    shape_flag: { fg: $catppuccin_macchiato.blue attr: "b" }
    shape_float: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_garbage: { fg: "#FFFFFF" bg: "#FF0000" attr: "b" }
    shape_globpattern: { fg: $catppuccin_macchiato.teal attr: "b" }
    shape_int: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_internalcall: { fg: $catppuccin_macchiato.teal attr: "b" }
    shape_list: { fg: $catppuccin_macchiato.teal attr: "b" }
    shape_literal: $catppuccin_macchiato.blue
    shape_match_pattern: $catppuccin_macchiato.green
    shape_matching_brackets: { attr: "u" }
    shape_nothing: $catppuccin_macchiato.teal
    shape_operator: $catppuccin_macchiato.peach
    shape_or: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_pipe: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_range: { fg: $catppuccin_macchiato.peach attr: "b" }
    shape_record: { fg: $catppuccin_macchiato.teal attr: "b" }
    shape_redirection: { fg: $catppuccin_macchiato.mauve attr: "b" }
    shape_signature: { fg: $catppuccin_macchiato.green attr: "b" }
    shape_string: $catppuccin_macchiato.green
    shape_string_interpolation: { fg: $catppuccin_macchiato.teal attr: "b" }
    shape_table: { fg: $catppuccin_macchiato.blue attr: "b" }
    shape_variable: $catppuccin_macchiato.mauve
    shape_vardecl: $catppuccin_macchiato.mauve
}

# Shell behavior
$env.config.show_banner = false
$env.config.edit_mode = "vi"
$env.config.shell_integration.osc2 = true
$env.config.shell_integration.osc7 = true
$env.config.shell_integration.osc133 = true
$env.config.shell_integration.osc633 = true
$env.config.cursor_shape.vi_insert = "line"
$env.config.cursor_shape.vi_normal = "block"

# History
$env.config.history.max_size = 1_000_000
$env.config.history.file_format = "sqlite"

# Completions
$env.config.completions.algorithm = "fuzzy"
$env.config.completions.case_sensitive = false

# Table display
$env.config.table.mode = "rounded"
$env.config.table.index_mode = "auto"

# Aliases
alias lg = lazygit
alias g = git
alias gs = git status --short --branch
alias gd = git diff
alias gds = git diff --staged
alias gl = git log --all --graph --pretty=format:'%C(magenta)%h %C(white) %an %ar%C(auto) %D%n%s%n'
alias v = nvim
alias vi = nvim
alias c = clear
alias e = exit

# eza (if available)
if (which eza | is-not-empty) {
    alias ls = eza -g -s Name --group-directories-first --time-style long-iso --icons=auto
    alias l = eza -g -s Name --group-directories-first --time-style long-iso --icons=auto -la
    alias la = eza -g -s Name --group-directories-first --time-style long-iso --icons=auto -la -a
    alias ll = eza -g -s Name --group-directories-first --time-style long-iso --icons=auto -l
}

# bat (if available)
if (which bat | is-not-empty) {
    alias cat = bat --style=plain --paging=auto
}

# fzf integration
$env.FZF_DEFAULT_OPTS = " --color=bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796 --color=fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6 --color=marker:#b7bdf8,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796 --color=selected-bg:#494d64 --multi"

# Ghostty term fix for SSH
if ($env.TERM? == "xterm-ghostty") {
    alias ssh = TERM=xterm-256color ssh
}
