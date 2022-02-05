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
	vim.cmd("split")
	self.win = vim.api.nvim_get_current_win()
	self.buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(self.win, self.buf)

	vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(self.buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(self.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(self.buf, "buflisted", false)
	vim.api.nvim_win_set_option(self.win, "winfixwidth", true)
	vim.api.nvim_win_set_option(self.win, "wrap", false)
	vim.api.nvim_win_set_option(self.win, "spell", false)
	vim.api.nvim_win_set_option(self.win, "list", false)
	vim.api.nvim_win_set_option(self.win, "winfixheight", true)
	vim.api.nvim_win_set_option(self.win, "signcolumn", "no")
	vim.api.nvim_win_set_option(self.win, "fcs", "eob: ")
	vim.api.nvim_buf_set_option(self.buf, "filetype", "DB")
end


function Window:fill()
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, 0, self.lines)
	vim.api.nvim_win_set_cursor(self.win, { 1, 1 })
end

function Window:printbla()
	print(self.origin)
end

return Window