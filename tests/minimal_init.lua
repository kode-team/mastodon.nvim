local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"
local sqlite_dir = os.getenv("SQLITE_DIR") or "/tmp/sqlite.nvim"
if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir })
end
if vim.fn.isdirectory(sqlite_dir) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/kkharji/sqlite.lua", sqlite_dir })
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(sqlite_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")
require("sqlite")
