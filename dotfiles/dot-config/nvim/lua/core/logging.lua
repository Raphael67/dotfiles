-- Persistent, rolling log for error/warning messages.
--
-- Why this exists: notifications (snacks.notifier and friends) are transient and
-- auto-dismiss, and Neovim's own `~/.local/state/nvim/log` only records core C-level
-- warnings -- never the Lua/LSP/plugin text that flashes on screen. This module captures
-- warn/error notifications to a real on-disk file that survives across sessions and
-- self-rotates.
--
-- Capture source: a `vim.notify` wrapper (warn/error only). snacks.notifier replaces
-- vim.notify with its own implementation; we wrap *that* so every notification it renders
-- is also logged. This is the path the vast majority of LSP/plugin warnings and errors
-- take.
--
-- NOTE: a previous version also hooked `vim.ui_attach(ext_messages)` to capture raw E###
-- errors. That mechanism suppresses the default on-screen message grid unless a UI renders
-- the messages (noice did). Since noice was removed in favor of the vanilla cmdline, that
-- source was dropped -- enabling it again would make ordinary messages disappear.

local uv = vim.uv or vim.loop

local LOG = vim.fn.stdpath("state") .. "/notifications.log"
local MAX_SIZE = 512 * 1024 -- rotate when the active log reaches 512 KB
local MAX_FILES = 3         -- keep notifications.log.1 .. .3 (oldest discarded)

local M = {}

-- Normalize a vim.notify level (number, "warn"/"error" string, or nil) to a numeric level.
local function level_value(level)
    if type(level) == "number" then
        return level
    elseif type(level) == "string" then
        return vim.log.levels[level:upper()]
    end
    return nil
end

-- Map a vim.log.levels value to a label; nil for anything below WARN (we don't log those).
local function level_name(level)
    if level == nil then
        return nil
    end
    if level >= vim.log.levels.ERROR then
        return "ERROR"
    elseif level >= vim.log.levels.WARN then
        return "WARN"
    end
    return nil
end

local function file_size(path)
    local st = uv.fs_stat(path)
    return st and st.size or 0
end

-- Rolling rotation: shift .2->.3, .1->.2, log->.1, drop the old .3. No-op until the cap is hit.
local function rotate_if_needed()
    if file_size(LOG) < MAX_SIZE then
        return
    end
    os.remove(LOG .. "." .. MAX_FILES)
    for i = MAX_FILES - 1, 1, -1 do
        os.rename(LOG .. "." .. i, LOG .. "." .. (i + 1))
    end
    os.rename(LOG, LOG .. ".1")
end

-- Append one record. Multi-line messages get their continuation lines indented under the header.
local function write(label, msg)
    msg = (msg or ""):gsub("%s+$", "")
    if msg == "" then
        return
    end
    rotate_if_needed()
    local f = io.open(LOG, "a")
    if not f then
        return
    end
    local stamp = os.date("%Y-%m-%dT%H:%M:%S")
    local indented = msg:gsub("\n", "\n    ")
    f:write(string.format("[%s] [%s] %s\n", stamp, label, indented))
    f:close()
end

-- Defer the actual file write so we never touch the filesystem in a fast/restricted context.
local function log(label, msg)
    vim.schedule(function()
        write(label, msg)
    end)
end

-- Build a logging wrapper around an existing notify function. Logs warn/error then delegates.
local function make_notify_wrapper(orig)
    return function(msg, level, opts)
        local label = level_name(level_value(level))
        if label then
            log(label, type(msg) == "string" and msg or tostring(msg))
        end
        return orig(msg, level, opts)
    end
end

-- Capture vim.notify warn/error. Deferred to after VeryLazy + a scheduled tick so snacks
-- has already installed its notifier; we then wrap whatever vim.notify currently is.
local function wrap_notify()
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
            vim.schedule(function()
                vim.notify = make_notify_wrapper(vim.notify)
            end)
        end,
    })
end

local function create_commands()
    vim.api.nvim_create_user_command("ErrorLog", function()
        vim.cmd("split " .. vim.fn.fnameescape(LOG))
    end, { desc = "Open the persistent error/warning log" })

    vim.api.nvim_create_user_command("ErrorLogClear", function()
        os.remove(LOG)
        for i = 1, MAX_FILES do
            os.remove(LOG .. "." .. i)
        end
        vim.notify("Error log cleared", vim.log.levels.INFO)
    end, { desc = "Clear the persistent error/warning log (and rotated files)" })
end

function M.setup()
    -- Keep the native LSP log meaningful without flooding it.
    vim.lsp.log.set_level(vim.log.levels.WARN)
    wrap_notify()
    create_commands()
end

M.setup()

return M
