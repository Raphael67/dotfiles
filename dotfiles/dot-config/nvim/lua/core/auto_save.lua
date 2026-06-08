-- Auto-save the current buffer when leaving insert mode.
--
-- Guarded so it only writes real, on-disk files: skips terminal/neo-tree/dadbod/help
-- and other special buffers (buftype ~= "") that would otherwise raise
-- `E382: Cannot write, 'buftype' option is set` on every InsertLeave.
-- `autowrite`/`autowriteall` (see core/options.lua) remain the buffer-switch safety net.
vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].buftype ~= "" then return end             -- skip terminal/nofile/neo-tree/etc.
        if not vim.bo[buf].modifiable then return end
        if not vim.bo[buf].modified then return end
        if vim.api.nvim_buf_get_name(buf) == "" then return end  -- skip unnamed buffers
        pcall(vim.cmd, "silent! write")
    end,
})
