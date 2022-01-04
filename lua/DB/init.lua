-- Docs
-- https://github.com/luvit/luv/blob/master/docs.md
-- Code from $HOME/.config/nvim/lua/functions.lua
local M = {}
local vim = vim
local api = vim.api
local uv = vim.loop

api.nvim_set_keymap('n', '<leader>ab', ":lua require('functions').DB()<CR>",
                    {noremap = true})

function M.get_selection()
    local s_start = vim.fn.getpos("'<")
    local s_end = vim.fn.getpos("'>")
    local n_lines = math.abs(s_end[2] - s_start[2]) + 1
    local lines = api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

    if next(lines) == nil then return {""} end

    lines[1] = string.sub(lines[1], s_start[3], -1)
    if n_lines == 1 then
        lines[n_lines] =
            string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
    else
        lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
    end
    return lines
end

-- Example:
-- https://github.com/smolck/nvim-todoist.lua/blob/2389aedf9831351433ab3806142b1e7e5dbddd22/lua/nvim-todoist.lua
function M.DB()
    local sql = M.get_selection()
    M.Write(sql)
    M.Execute(function(res)
        M.open_window(res)
    end)
end

-- TODO: implement preview function in lua
-- function M.ShowPreview() end

function M.Write(str)
    local path = '/tmp/db.sql'
    local fd = uv.fs_open(path, 'w', 438)
    uv.fs_write(fd, str, -1)
    uv.fs_close(fd)
end

function M.Execute(cb)
    vim.fn.jobstart(string.format('vimdb %s',
                                  vim.fn.toupper(vim.env.stage) .. ' /tmp/db.sql'),
                    {
        stdout_buffered = true,
        on_stdout = function(_, data, _) cb(data) end
    })
end

function M.open_window(lines)

    vim.cmd([[
        pclose
        keepalt new +setlocal\ previewwindow|setlocal\ buftype=nofile|setlocal\ noswapfile|setlocal\ wrap [Jira]
        setl bufhidden=wipe
        setl buftype=nofile
        setl noswapfile
        setl nobuflisted
        setl nospell
        exe 'setl filetype=text'
        setl conceallevel=0
        setl nofoldenable
        setl nowrap
      ]])
    vim.api.nvim_buf_set_lines(0, 0, -1, 0, lines)

    vim.cmd('exe "normal! z" .' .. #lines .. '. "\\<cr>"')
    vim.cmd([[
        exe "normal! gg"
        wincmd P
        res 15
      ]])

end

return M
