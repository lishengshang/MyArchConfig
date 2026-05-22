-- lua/plugins/telescope.lua
-- 模糊查找器：文件搜索、内容搜索

return {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        require("telescope").setup({})
        vim.keymap.set("n", "<leader>ff", ":Telescope find_files<CR>", { desc = "查找文件" })
        vim.keymap.set("n", "<leader>fg", ":Telescope live_grep<CR>", { desc = "实时搜索内容" })
    end,
}
