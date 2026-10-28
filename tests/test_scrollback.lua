-- Run with: nvim --headless -u NONE -i NONE -l tests/test_scrollback.lua
local source = debug.getinfo(1, "S").source:sub(2)
local root = vim.fs.dirname(vim.fs.dirname(source))
local scrollback = dofile(root .. "/lua/tmux_scrollback.lua")
local directory = vim.fn.tempname() .. " with spaces"
vim.fn.mkdir(directory, "p")
local capture = directory .. "/output"
local copied

vim.g.clipboard = {
    name = "Scrollback test provider",
    copy = {
        ["+"] = function(lines, register_type)
            copied = { lines = lines, register_type = register_type }
        end,
        ["*"] = function() error("Unexpected primary clipboard write") end,
    },
    paste = { ["+"] = function() return { "" }, "v" end, ["*"] = function() return { "" }, "v" end },
}

local function verify()
    vim.fn.writefile({ "\27[38;2;255;0;0mred\27[0m café 🌍", "界 target", "third line" }, capture)
    vim.env.NVIM_SCROLLBACK_FILE = capture
    vim.env.NVIM_SCROLLBACK_ROW = "2"
    vim.env.NVIM_SCROLLBACK_COLUMN = "3"
    scrollback.open()
    assert(vim.wait(1000, function()
        return vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == "red café 🌍"
            and vim.api.nvim_win_get_cursor(0)[1] == 2
    end), "The terminal output or cursor did not become ready")

    local lines = vim.api.nvim_buf_get_lines(0, 0, 3, false)
    assert(lines[1] == "red café 🌍", vim.inspect(lines))
    assert(lines[2] == "界 target", vim.inspect(lines))
    assert(lines[3] == "third line", vim.inspect(lines))
    assert(vim.api.nvim_win_get_cursor(0)[2] == 4, "Display cells did not map to the UTF-8 byte column")
    assert(vim.fn.mode() == "n", "The viewer did not start in normal mode")

    vim.cmd("normal! yiw")
    assert(vim.fn.getreg('"') == "target", "The normal yank or word text object failed")
    assert(copied == nil, "An unnamed yank wrote to the system clipboard")

    vim.keymap.set({ "n", "x" }, "+", '"+')
    vim.cmd("normal +yiw")
    assert(copied.lines[1] == "target", "The explicit clipboard yank bypassed the configured provider")

    local original_read = io.read
    io.read = function() return "café 🌍\nsecond line\n" end
    scrollback.copy_stdin()
    io.read = original_read
    assert(table.concat(copied.lines, "\n") == "café 🌍\nsecond line\n", "Clipboard text changed")

    assert(vim.bo.buftype == "terminal", "ANSI output did not use Neovim's terminal renderer")
    assert(not vim.bo.modified, "The viewer requires a forced quit")
end

local ok, message = xpcall(verify, debug.traceback)
vim.fn.delete(directory, "rf")
if not ok then
    io.stderr:write(message .. "\n")
    vim.cmd("cquit 1")
end
print("Terminal scrollback tests passed")
vim.cmd("qa!")
