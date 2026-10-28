local M = {}

-- Use the clipboard provider from the normal Neovim configuration.
function M.copy_stdin()
    vim.fn.setreg("+", io.read("*a"), "v")
end

function M.open()
    local capture_file = assert(vim.env.NVIM_SCROLLBACK_FILE, "Missing scrollback capture")
    local file = assert(io.open(capture_file, "rb"))
    local text = file:read("*a")
    file:close()

    local buffer = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_current_buf(buffer)
    vim.api.nvim_buf_set_name(buffer, "Terminal scrollback")
    vim.bo[buffer].scrollback = 100000
    vim.b[buffer].auto_save = 0

    -- Replay tmux's text and SGR attributes through Neovim's terminal renderer.
    -- Physical rows preserve the pane layout. The capture contains no live job.
    local channel = vim.api.nvim_open_term(buffer, {})
    local function restore_cursor()
        local row = tonumber(vim.env.NVIM_SCROLLBACK_ROW) or 1
        local column = tonumber(vim.env.NVIM_SCROLLBACK_COLUMN) or 0
        row = math.min(row, vim.api.nvim_buf_line_count(buffer))
        vim.api.nvim_win_set_cursor(0, { row, 0 })
        -- tmux reports display cells, whereas Neovim cursor columns use bytes.
        vim.cmd("normal! " .. (column + 1) .. "|")
        vim.cmd("normal! zb")
        vim.bo[buffer].modified = false
    end

    -- Position the cursor after the terminal renders, rather than in its empty grid.
    vim.api.nvim_buf_attach(buffer, false, {
        on_lines = function()
            vim.schedule(restore_cursor)
            return true
        end,
    })
    vim.api.nvim_chan_send(channel, (text:gsub("\n", "\r\n")))
    vim.cmd.stopinsert()

    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { buffer = buffer })
end

return M
