fun! DB() range abort
    call Reload()
    lua require("DB").DB()
endfun

fun! ShowPreview() range abort
    call Reload()
    lua require("DB").ShowPreview()
endfun

fun! CountNrRows() range abort
    call Reload()
    lua require("DB").CountNrRows()
endfun

fun! ShowJobs() range abort
    call Reload()
    lua require("DB").ShowJobs()
endfun

fun! DBSelection() range abort
    call Reload()
    lua require("DB").db_selection()
endfun

fun! Reload()
    lua for k in pairs(package.loaded) do if k:match("^DB") then package.loaded[k] = nil end end
endfun

map <leader>pp :call DB()<CR>
map <leader>pv :call ShowPreview()<CR>
map <leader>pn :call CountNrRows()<CR>
map <leader>pj :call ShowJobs()<CR>
map <leader>pc :call DBSelection()<CR>


lua << EOF

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

    opts = {
        dbs = DBS
    }

    DB = require("DB")
    db = DB:new(opts)
    " TODO: Hier gebleven. Trying to instantiate DB from here?

EOF

