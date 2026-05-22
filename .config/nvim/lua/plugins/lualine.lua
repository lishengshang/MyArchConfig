-- lua/plugins/lualine.lua
-- 状态栏：底部信息栏（模式、文件名、Git 分支等）

return {
    "nvim-lualine/lualine.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "catppuccin/nvim",
    },
    config = function()
        require("lualine").setup({
            options = { theme = "auto" },
        })
    end,
}
