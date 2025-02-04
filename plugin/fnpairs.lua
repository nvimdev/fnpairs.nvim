if vim.g.load_fnpairs ~= nil then
  return
end

vim.g.load_fnpairs = true

require('fnpairs').setup()
