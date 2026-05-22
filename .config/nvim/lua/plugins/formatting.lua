-- lua/plugins/formatting.lua
-- 代码格式化：conform.nvim

return {
    "stevearc/conform.nvim",
    config = function()
        require("conform").setup({
            formatters_by_ft = {
                c = { "clang_format" },
            },
        })
        vim.keymap.set("n", "<leader>cf", function()
            require("conform").format()
        end, { desc = "格式化代码" })
    end,
}
