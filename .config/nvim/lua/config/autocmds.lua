-- Matugen 颜色热重载：收到 SIGUSR1 信号时重新加载生成的颜色配置
local matugen_group = vim.api.nvim_create_augroup("matugen_reload", { clear = true })

vim.api.nvim_create_autocmd("Signal", {
  group = matugen_group,
  pattern = "SIGUSR1",
  callback = function()
    local matugen_path = vim.fn.stdpath("config") .. "/generated.lua"
    local f = io.open(matugen_path, "r")
    if f then
      io.close(f)
      local ok, err = pcall(dofile, matugen_path)
      if ok then
        vim.notify("Matugen 颜色已更新")
      else
        vim.notify("Matugen Reload Error: " .. err, vim.log.levels.ERROR)
      end
    end
  end,
})

-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- fcitx5: 插入模式自动切换中英文输入法
local fcitx_group = vim.api.nvim_create_augroup("fcitx5_auto", { clear = true })

local function fcitx5_cmd(args)
  vim.fn.jobstart({ "fcitx5-remote", args })
end

do
  local handle = io.popen("fcitx5-remote")
  if handle then
    local state = handle:read("*a"):gsub("%s+", "")
    handle:close()
    vim.g.fcitx5_prior_state = state
    fcitx5_cmd("-c")
  end
end

vim.api.nvim_create_autocmd("InsertLeave", {
  group = fcitx_group,
  callback = function()
    fcitx5_cmd("-c")
  end,
})

vim.api.nvim_create_autocmd("InsertEnter", {
  group = fcitx_group,
  callback = function()
    fcitx5_cmd("-o")
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  group = fcitx_group,
  callback = function()
    local prior = vim.g.fcitx5_prior_state
    if prior == "2" then
      os.execute("fcitx5-remote -o")
    elseif prior == "1" then
      os.execute("fcitx5-remote -c")
    end
  end,
})