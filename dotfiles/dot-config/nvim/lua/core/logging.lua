-- Persistent, rolling log for error/warning messages.
--
-- Why this exists: noice.nvim shows messages in a transient view that auto-dismisses,
-- and Neovim's own `~/.local/state/nvim/log` only records core C-level warnings -- never
-- the Lua/LSP/command-error text that flashes red on screen. This module captures those
-- error/warn messages to a real on-disk file that survives across sessions and self-rotates.
--
-- Two capture sources, both filtered to ERROR/WARN only:
--   1. vim.ui_attach(ext_messages)  -> the hard red errors (E### errors, Lua errors, ...)
--   2. a vim.notify wrapper         -> programmatic notifications (most LSP/plugin warnings)
-- noice replaces vim.notify on VeryLazy and renders notifications itself (bypassing msg_show),
-- so both sources are needed for full coverage.

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

-- msg_show `kind` -> label. Only error/warning kinds are logged; everything else is ignored.
local function kind_label(kind)
    if kind == "emsg" or kind == "echoerr" or kind == "lua_error"
        or kind == "rpc_error" or kind == "shell_err" then
        return "ERROR"
    elseif kind == "wmsg" then
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

-- ui callbacks run in a restricted/fast context: defer the actual file write.
local function log(label, msg)
    vim.schedule(function()
        write(label, msg)
    end)
end

-- Concatenate the text out of an ext_messages `content` chunk list ({ {attr, text, hl}, ... }).
local function chunks_to_text(content)
    local parts = {}
    for _, chunk in ipairs(content or {}) do
        parts[#parts + 1] = chunk[2] or ""
    end
    return table.concat(parts)
end

-- Source 1: observe every on-screen message. Passive -- never returns true (which would
-- suppress the message) and coexists with noice's own ext_messages handler.
local function attach_messages()
    local ns = vim.api.nvim_create_namespace("core_logging_messages")
    vim.ui_attach(ns, { ext_messages = true }, function(event, ...)
        if event ~= "msg_show" then
            return
        end
        local kind, content = ...
        local label = kind_label(kind)
        if label then
            log(label, chunks_to_text(content))
        end
    end)
end

-- Build a logging wrapper around an existing notify function. Logs warn/error then delegates.
-- Skips logging while in a fast event: noice reschedules those onto the main loop, where the
-- wrapper runs again -- gating here keeps each notification logged exactly once.
local function make_notify_wrapper(orig)
    return function(msg, level, opts)
        if not vim.in_fast_event() then
            local label = level_name(level_value(level))
            if label then
                log(label, type(msg) == "string" and msg or tostring(msg))
            end
        end
        return orig(msg, level, opts)
    end
end

-- Source 2: capture vim.notify warn/error too (noice renders these itself, bypassing msg_show).
-- Deferred to after VeryLazy + a scheduled tick so noice has already installed its handler.
-- When noice owns vim.notify, wrap its source *in place* so both `vim.notify` and noice's own
-- reference stay identical -- otherwise noice's health checker flags a spurious
-- "vim.notify has been overwritten" error. Falls back to a plain wrapper if noice is absent.
local function wrap_notify()
    vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = function()
            vim.schedule(function()
                local ok, src = pcall(require, "noice.source.notify")
                if ok and type(src) == "table" and src.notify == vim.notify then
                    local wrapper = make_notify_wrapper(src.notify)
                    src.notify = wrapper -- keep noice's health check (want == handler) satisfied
                    vim.notify = wrapper
                else
                    vim.notify = make_notify_wrapper(vim.notify)
                end
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
    attach_messages()
    wrap_notify()
    create_commands()
end

M.setup()

return M
