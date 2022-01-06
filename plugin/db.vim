fun! DB() range abort
    lua for k in pairs(package.loaded) do if k:match("^DB") then package.loaded[k] = nil end end
    lua require("DB").DB()
endfun

fun! DP() range abort
    lua for k in pairs(package.loaded) do if k:match("^DB") then package.loaded[k] = nil end end
    lua require("DB").ShowPreview()
endfun

map <leader>pp :call DB()<CR>
map <leader>pv :call DP()<CR>

