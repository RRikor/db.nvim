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

fun! SwitchDB() range abort
    call Reload()
    lua require("DB").db_selection()
endfun

fun! TableDetails() range abort
    call Reload()
    lua require("DB").table_details()
endfun

fun! DBFuzzy() range abort
    call Reload()
    lua require("DB").render_fuzzy()
endfun

fun! Reload()
    lua for k in pairs(package.loaded) do if k:match("^DB") then package.loaded[k] = nil end end
endfun

map <leader>pp :call DB()<CR>
map <leader>pv :call ShowPreview()<CR>
map <leader>pc :call CountNrRows()<CR>
map <leader>pj :call ShowJobs()<CR>
map <leader>ps :call SwitchDB()<CR>
map <leader>p+ :call TableDetails()<CR>
map <leader>pf :call DBFuzzy()<CR>



