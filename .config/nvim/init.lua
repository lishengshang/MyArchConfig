-- ~/.config/nvim/init.lua
-- Neovim 0.11+ 入口文件
-- 采用 lazy.nvim 推荐的模块化目录结构
--   lua/config/   → 核心 Neovim 配置（options、keymaps、LSP）
--   lua/plugins/  → 插件规格（每个文件 return {...}）

-- 1. 核心配置（最先加载，确保 options / keymaps 立即生效）
require("config.options")
require("config.keymaps")

-- 2. lazy.nvim 引导
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
    vim.fn.system({
        "git", "clone", "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

-- 3. 加载插件（lazy.nvim 自动扫描 lua/plugins/*.lua）
require("lazy").setup("plugins")

-- 4. LSP 配置（使用 autocmd 模式，不依赖插件加载顺序）
require("config.lsp")
