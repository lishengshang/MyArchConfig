-- lua/plugins/gitsigns.lua
-- Git 集成：行号左侧显示增删改标记

return {
    "lewis6991/gitsigns.nvim",
    config = function()
        require("gitsigns").setup()
    end,
}
