-- Docs
-- https://github.com/luvit/luv/blob/master/docs.md
-- Code from $HOME/.config/nvim/lua/functions.lua
-- Windows: https://www.2n.pl/blog/how-to-make-ui-for-neovim-plugins-in-lua
-- Floating windows:  https://www.2n.pl/blog/how-to-write-neovim-plugins-in-lua
local DB = {}
local vim = vim
local api = vim.api
local uv = vim.loop
local Window = require("DB.window")
local window

local DBS = {}
DBS[1] = {
	name = "woco-dev",
	conn = 'psql --host="$RDSDBDEV" --port=5432 --username="$DB_OCTOCVDB_DEV_ROOT_USER" --password --dbname="$DB_OCTOCVDB_DEV_NAME" -w -L ~/psql.log -f %s 2>&1',
}
DBS[2] = {
	name = "woco-prd",
	conn = 'psql --host="$RDSDB" --port=5432 --username="$DB_OCTOCVDB_PRD_ROOT_USER" --password --dbname="$DB_OCTOCVDB_PRD_NAME" -w -L ~/psql.log -f %s 2>&1',
}
DBS[3] = {
	name = "spotr-domain-dev",
	conn = "psql --host=$RDSDOMAINACC --port=5432 --username=$DB_DOMAIN_API_PRD_USER --password --dbname=$DB_DOMAIN_API_PRD_NAME -w -L ~/psql.log -f %s 2>&1",
}
DBS[4] = {
	name = "spotr-domain-prd",
	conn = "psql --host=$RDSDOMAINPRD --port=5432 --username=$DB_DOMAIN_API_DEV_USER --password --dbname=$DB_DOMAIN_API_DEV_NAME -w -L ~/psql.log -f %s 2>&1",
}
DBS[5] = {
	name = "FM - Redshift",
	conn = "psql --host=$REDSHIFT --port=5439 --username=$DB_REDSHIFT_USER --password --dbname=$DB_REDSHIFT_NAME -w -L ~/psql.log -f %s 2>&1",
}
if not vim.g.dbconn then
	vim.g.dbconn = DBS[1]
end

function DB.get_selection()
	local s_start = vim.fn.getpos("'<")
	local s_end = vim.fn.getpos("'>")
	local n_lines = math.abs(s_end[2] - s_start[2]) + 1
	local lines = api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)

	if next(lines) == nil then
		return { "" }
	end

	lines[1] = string.sub(lines[1], s_start[3], -1)
	if n_lines == 1 then
		lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
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
function DB.DB()
	DB.SetCurrentPosition()
	local sql = DB.get_selection()
	DB.Write(sql)
	DB.Execute(sql)
end

function DB.SetCurrentPosition()
	local win = vim.api.nvim_get_current_win()
	local cursor = vim.api.nvim_win_get_cursor(win)
	CurrentPos["window"] = win
	CurrentPos["cursor"] = cursor
end

function DB.ShowPreview()
	DB.SetCurrentPosition()
	local wordUnderCursor = vim.fn.expand("<cword>")
	local line = vim.fn.getline(".")

	if vim.fn.strpart(line, vim.fn.stridx(line, wordUnderCursor) - 1, 1) == "." then
		local schema = vim.fn.matchstr(line, [[\v(\w*)(\.\@=)]])
		local sqlstr = "select * from " .. schema .. wordUnderCursor .. " limit 50;"

		local sql = { sqlstr }
		DB.Execute(sql)
	else
		print("not working yet")
	end
end

function DB.CountNrRows()
	DB.SetCurrentPosition()
	local wordUnderCursor = vim.fn.expand("<cword>")
	local line = vim.fn.getline(".")

	if vim.fn.strpart(line, vim.fn.stridx(line, wordUnderCursor) - 1, 1) == "." then
		local schema = vim.fn.matchstr(line, [[\v(\w*)(\.\@=)]])
		local sqlstr = "select count(*) from " .. schema .. wordUnderCursor .. ";"

		local sql = { sqlstr }
		DB.Execute(sql)
	else
		print("not working yet")
	end
end

function DB.ShowJobs()
	DB.SetCurrentPosition()

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
	DB.Execute(sql)

	vim.api.nvim_buf_set_keymap(
		0,
		"n",
		"c",
		':lua require("DB").StopJob()<CR>',
		{ nowait = true, noremap = true, silent = true }
	)
end

function DB.StopJob()
	local wordUnderCursor = vim.fn.expand("<cword>")
	local sql = "select pg_terminate_backend('" .. wordUnderCursor .. "')"
    print(sql)
	-- DB.Execute(sql)
end

function DB.CancelQuery()
	if JobId ~= nil then
		vim.fn.jobstop(JobId)
	end
end

function DB.Write(sql_table)
	if type(sql_table) == "string" then
		sql_table = vim.fn.split(sql_table, "\n")
	end

	local path = "/tmp/db.sql"
	local fd = uv.fs_open(path, "w", 438)

	for _, line in ipairs(sql_table) do
		uv.fs_write(fd, line .. "\n", -1)
	end

	uv.fs_close(fd)
end

-- TODO: DB selection works, try with <leader>pc. Now hook DB selection up with execute method here
function DB.Execute(sql)
	DB.Write(sql)

	local job = string.format(vim.g.dbconn.conn, "/tmp/db.sql")

	JobId = vim.fn.jobstart(string.format(job), {
		-- TODO: this can be put on false, but then it will display a new empty window for
		-- each result. Figure out how to append the result to the window and not overwrite
		stdout_buffered = true,
		stderr_buffered = true,
		on_stdout = function(_, data, _)
			if data[1] ~= "" then
				DB.render(data, false)
			end
		end,
		on_stderr = function(_, err, _)
			if err[1] ~= "" then
				print(vim.inspect(err))
			end
		end,
	})

	local executing = {}
	table.insert(executing, "Executing on " .. vim.g.dbconn.name .. "...")
	table.insert(executing, "")

	if type(sql) == "table" then
	elseif type(sql == "string") then
		sql = vim.fn.split(sql, "\n")
	end

	for _, data in ipairs(sql) do
		table.insert(executing, data)
	end

	-- M.open_window(executing, true)
end

function DB.render(lines, return_cursor)
	local opts = {
        -- TODO: Implement this
		origin = "original_cursor_position",
		value = 1,
		lines = lines,
		buf = vim.g.dbbuf,
	}

    -- TODO: This has to be moved into execute. Since this only triggers when
    -- the query returned, the keybindings of the StopJob do not get attached.
	window = Window:new(opts)
	if not DB.window_valid() then
		window:create()
		window:fill()
		vim.g.dbbuf = window.buf
		vim.g.dbwin = window.win
	else
		window:fill(vim.g.dbbuf, vim.g.dbwin)
	end
end

function DB.window_valid()
	if vim.g.dbbuf then
		return vim.api.nvim_buf_is_valid(vim.g.dbbuf)
	end
	return false
end

function DB.db_selection()
	-- local start_win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

	-- get dimensions
	local editorWidth = vim.api.nvim_get_option("columns")
	local editorHeight = vim.api.nvim_get_option("lines")

	local height = math.ceil(editorHeight * 0.2 - 5)
	local width = math.ceil(editorWidth * 0.2 - 10)
	local opts = {
		style = "minimal",
		border = "shadow",
		relative = "editor",
		height = height,
		width = width,
		row = math.ceil((editorHeight - height) / 2 - 1),
		col = math.ceil((editorWidth - width) / 2),
	}
	-- and finally create it with buffer attached
	local win = vim.api.nvim_open_win(buf, true, opts)
	vim.api.nvim_buf_set_lines(buf, 0, 0, -1, DB.format_dbs())
    vim.api.nvim_win_set_cursor(win, {1,0})

	vim.api.nvim_buf_set_keymap(
		0,
		"n",
		"<CR>",
		':lua require("DB").set_db(' .. win .. ")<CR>",
		{ nowait = true, noremap = true, silent = true }
	)
end

function DB.format_dbs()
	local lines = {}
	for key, db in ipairs(DBS) do
		table.insert(lines, key .. " • " .. db.name)
	end

	return lines
end

function DB.set_db(win)
	local line = vim.fn.getline(".")
	local id = string.sub(line, 1, 1)
	vim.g.dbconn = DBS[tonumber(id)]
    print("Switching connection to", vim.g.dbconn.name)
	vim.api.nvim_win_close(win, true)
end

return DB
