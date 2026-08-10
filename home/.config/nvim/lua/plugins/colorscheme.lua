return {
  -- 告诉 LazyVim 使用 habamax 作为默认 colorscheme，避免加载 tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "habamax",
    },
  },

  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local function load_matugen()
        local matugen_path = vim.fn.stdpath("config") .. "/generated.lua"
        local f = io.open(matugen_path, "r")
        if f then
          io.close(f)
          local ok, err = pcall(dofile, matugen_path)
          if not ok then
            vim.notify("Matugen Load Error: " .. err, vim.log.levels.ERROR)
            vim.cmd.colorscheme("habamax")
          end
        else
          vim.cmd.colorscheme("habamax")
        end
      end

      -- 首次加载
      load_matugen()

      -- LazyVim 可能在 VimEnter 后设置 colorscheme，在 VeryLazy 后重新加载
      vim.api.nvim_create_autocmd("User", {
        pattern = "VeryLazy",
        once = true,
        callback = load_matugen,
      })
    end,
  },
}
