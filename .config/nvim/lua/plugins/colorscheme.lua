-- lua/plugins/colorscheme.lua
-- 主题：catppuccin (mocha)

return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
        require("catppuccin").setup({ flavour = "mocha" })
        vim.cmd.colorscheme("catppuccin")
    end,
}
