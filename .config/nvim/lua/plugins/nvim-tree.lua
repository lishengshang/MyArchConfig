-- lua/plugins/nvim-tree.lua
-- 文件树：侧边栏文件浏览器

return {
    "nvim-tree/nvim-tree.lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        require("nvim-tree").setup({})
        vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "切换文件树" })
    end,
}
