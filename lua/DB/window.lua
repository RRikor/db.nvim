-- [[
-- vim.cmd('vsplit')
-- local win = vim.api.nvim_get_current_win()
-- local buf = vim.api.nvim_create_buf(true, true)
-- vim.api.nvim_win_set_buf(win, buf)
-- ]]

local Window = {}
Window.__index = Window

function Window:new(opts)
    local this = {
        origin = opts.origin,
        value = opts.value,
        lines = opts.lines,
    }
    setmetatable(this, self)
    return this
end

function Window:create()
    vim.cmd('split')
    -- self.win = vim.api.nvim_get_current_win()
    -- self.buf = vim.api.nvim_create_buf(true, true)
    -- vim.api.nvim_win_set_buf(self.win, self.buf)
	-- vim.api.nvim_buf_set_lines(0, 0, -1, 0, self.lines)
end

function Window:printbla()
    print(self.origin)
end


return Window
