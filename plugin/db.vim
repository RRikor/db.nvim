fun! DB()
    lua for k in pairs(package.loaded) do if k:match("^DB") then package.loaded[k] = nil end end
    lua require("DB").DB()
endfun

map <leader>pp :call DB()<CR>

