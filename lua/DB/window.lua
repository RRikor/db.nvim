local Window = {}
Window.__index = Window

function Window:new(opts)
	local this = {
		origin = opts.origin,
		value = opts.value,
		lines = opts.lines,
		buff = opts.buff,
        keys = opts.keys,
	}
	setmetatable(this, self)
	return this
end

function Window:create()

	vim.cmd("split")
	self.win = vim.api.nvim_get_current_win()
	self.buf = vim.api.nvim_create_buf(true, true)
	vim.api.nvim_win_set_buf(self.win, self.buf)
    vim.api.nvim_win_set_height(self.win, 20)

	vim.api.nvim_buf_set_option(self.buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(self.buf, "buftype", "nowrite")
	vim.api.nvim_buf_set_option(self.buf, "swapfile", false)
	vim.api.nvim_buf_set_option(self.buf, "buflisted", false)
	vim.api.nvim_win_set_option(self.win, "wrap", false)
	vim.api.nvim_win_set_option(self.win, "spell", false)
	vim.api.nvim_win_set_option(self.win, "list", false)
	vim.api.nvim_win_set_option(self.win, "signcolumn", "no")
	vim.api.nvim_win_set_option(self.win, "fcs", "eob: ")
	vim.api.nvim_buf_set_option(self.buf, "filetype", "DB")

    local keyopts = { nowait = true, noremap = true, silent = true }
    if self.keys ~= nil then
        for _, value in pairs(self.keys) do
            vim.api.nvim_buf_set_keymap(self.buf, "n", value[1], value[2] .. '<CR>', keyopts)
        end
    end

    vim.api.nvim_buf_set_keymap(self.buf, "n", "f", ':lua require("DB").Filter()<CR>', keyopts)
end

function Window:fill(buf, win)
    buf = buf or self.buf
    win = win or self.win

	vim.api.nvim_buf_set_lines(buf, 0, -1, 0, self.lines)
	vim.api.nvim_win_set_cursor(win, { 1, 1 })
end

function Window:clear()
	local lines = {}
	vim.api.nvim_buf_set_lines(self.buf, 0, -1, 0, lines)
end

return Window
