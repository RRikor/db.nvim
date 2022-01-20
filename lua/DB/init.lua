-- Docs
-- https://github.com/luvit/luv/blob/master/docs.md
-- Code from $HOME/.config/nvim/lua/functions.lua
-- Windows: https://www.2n.pl/blog/how-to-make-ui-for-neovim-plugins-in-lua
-- Floating windows:  https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
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

CurrentPos = {}
-- Example:
-- https://github.com/smolck/nvim-todoist.lua/blob/2389aedf9831351433ab3806142b1e7e5dbddd22/lua/nvim-todoist.lua
-- TODO: Run 'select pg_backend_pid();' to receive the pid of the query we are about
-- to execute. This is necessary for cancelling a query. However this is not possible when using psql.
-- So solution: create a small backend to keep the connection
-- open, get the pid, run the query and save the pid so we can cancel if necessary.
function M.DB()
    M.SetCurrentPosition()
    local sql = M.get_selection()
    M.Write(sql)
    M.Execute(sql)
end

function M.SetCurrentPosition()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(win)
    CurrentPos['window'] = win
    CurrentPos['cursor'] = cursor
end

function M.ShowPreview()
    M.SetCurrentPosition()
    local wordUnderCursor = vim.fn.expand("<cword>")
    local line = vim.fn.getline('.')

    if vim.fn.strpart(line, vim.fn.stridx(line, wordUnderCursor) - 1, 1) == '.' then
        local schema = vim.fn.matchstr(line, [[\v(\w*)(\.\@=)]])
        local sqlstr = 'select * from ' .. schema .. wordUnderCursor ..
                           ' limit 50;'

        local sql = {sqlstr}
        M.Execute(sql)
    else
        print("not working yet")
    end
end

function M.CountNrRows()
    M.SetCurrentPosition()
    local wordUnderCursor = vim.fn.expand("<cword>")
    local line = vim.fn.getline('.')

    if vim.fn.strpart(line, vim.fn.stridx(line, wordUnderCursor) - 1, 1) == '.' then
        local schema = vim.fn.matchstr(line, [[\v(\w*)(\.\@=)]])
        local sqlstr = 'select count(*) from ' .. schema .. wordUnderCursor ..
                           ';'

        local sql = {sqlstr}
        M.Execute(sql)
    else
        print("not working yet")
    end
end

function M.ShowJobs()
    M.SetCurrentPosition()

    local sql = [[
        select 
            pid
            , query
        from pg_stat_activity
        where pid in (
            SELECT distinct 
                l.pid 
            FROM pg_locks l 
            JOIN pg_stat_all_tables t ON l.relation = t.relid 
            left join pg_stat_activity as t2 on ( 
                l.pid = t2.pid ) 
            WHERE 
                t.schemaname <> 'pg_toast'::name 
                AND t.schemaname <> 'pg_catalog'::name
        );]]
    M.Execute(sql)

    vim.api.nvim_buf_set_keymap(0, 'n', 'c', "lua require('DB').StopJob()  ",
                                {nowait = true, noremap = true, silent = true})
end

function M.StopJob()

    local wordUnderCursor = vim.fn.expand("<cword>")
    local sql = 'select pg_terminate_backend(' .. wordUnderCursor .. '):'
    M.Execute(sql)
end

function M.CancelQuery() if JobId ~= nil then vim.fn.jobstop(JobId) end end

function M.Write(sql_table)

    if type(sql_table) == 'string' then
        sql_table = vim.fn.split(sql_table, '\n')
    end

    local path = '/tmp/db.sql'
    local fd = uv.fs_open(path, 'w', 438)

    for _, line in ipairs(sql_table) do uv.fs_write(fd, line .. '\n', -1) end

    uv.fs_close(fd)

end

function M.Execute(sql)
    M.Write(sql)

    -- TODO: vimdb can probably be integrated in here
    JobId = vim.fn.jobstart(string.format('vimdb %s', vim.fn
                                              .toupper(vim.env.stage) ..
                                              ' /tmp/db.sql'), {
        -- TODO: this can be put on false, but then it will display a new empty window for
        -- each result. Figure out how to append the result to the window and not overwrite
        stdout_buffered = true,
        stderr_buffered = true,
        on_stdout = function(_, data, _)
            if data[1] ~= "" then M.open_window(data, false) end
        end,
        on_stderr = function(_, err, _)
            if err[1] ~= "" then print(vim.inspect(err)) end
        end
    })

    local executing = {}
    table.insert(executing, "Executing on " .. vim.env.stage .. "...")
    table.insert(executing, "")

    if type(sql) == 'table' then
    elseif type(sql == 'string') then
        sql = vim.fn.split(sql, '\n')
    end

    for _, data in ipairs(sql) do table.insert(executing, data) end

    M.open_window(executing, true)

end

function M.open_window(lines, return_cursor)

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
        res 15
      ]])

    vim.api.nvim_buf_set_keymap(0, 'n', 'q', ':pclose<cr>',
                                {nowait = true, noremap = true, silent = true})

    -- if return_cursor == true then
    vim.api.nvim_win_set_cursor(CurrentPos['window'], CurrentPos['cursor'])
    -- end

end

-- TODO: Finish the selection with actually connecting to the selected db
function M.db_selection()

    local dbs = {
        "1. woco-dev",
        "2. woco-prd",
        "3. spotr-domain-dev",
        "4. spotr-domain-prd",
        "5. fm - redshift"
    }

    -- local start_win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')

    -- get dimensions
    local editorWidth = vim.api.nvim_get_option("columns")
    local editorHeight = vim.api.nvim_get_option("lines")

    local height = math.ceil(editorHeight * 0.2 - 4)
    local width = math.ceil(editorWidth * 0.2)
    local opts = {
        style = "minimal",
        border = "rounded",
        relative = "editor",
        height = height,
        width = width,
        row = math.ceil((editorHeight - height) / 2 - 1),
        col = math.ceil((editorWidth - width) / 2)
    }
    -- and finally create it with buffer attached
    vim.api.nvim_open_win(buf, true, opts)
    vim.api.nvim_buf_set_lines(buf, 0, 0, -1, dbs)

    vim.api.nvim_buf_set_keymap(0, 'n', '<CR>', 'lua require("db").set_db()<cr>',
                                {nowait = true, noremap = true, silent = true})
end

function M.set_db()

end

return M

