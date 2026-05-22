-- lua/config/options.lua
-- 基础编辑器设置（vim.opt / vim.g）

-- 行号
vim.opt.number = true
vim.opt.relativenumber = true

-- 加入数位限制
vim.opt.colorcolumn = "80"

-- 高亮
vim.opt.cursorline = true

-- 缩进：4 空格
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

-- 搜索
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 显示
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.termguicolors = true
vim.opt.updatetime = 50
vim.opt.timeoutlen = 300
vim.opt.signcolumn = "auto"

vim.opt.autoread = true 

-- 编码
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- 文件持久化
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true

-- undo 持久化目录
local undo_dir = vim.fn.stdpath("state") .. "/undo"
vim.fn.mkdir(undo_dir, "p")
vim.opt.undodir = undo_dir

-- 系统剪贴板
vim.opt.clipboard = "unnamedplus"

-- Leader 键
vim.g.mapleader = " "
vim.g.maplocalleader = " "
