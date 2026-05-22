-- lua/plugins/hop.lua
-- 快速跳转：用最少按键跳转到屏幕任意位置

return {
    "smoka7/hop.nvim",
    -- 按需加载：仅在调用 Hop 命令时加载
    keys = {
        { "<leader>j", desc = "跳转" },
        { "<leader>jw", desc = "跳转到单词" },
        { "<leader>jl", desc = "跳转到行" },
        { "<leader>jc", desc = "跳转到字符" },
        { "<leader>jj", desc = "跳转到任意位置" },
    },
    config = function()
        local hop = require("hop")
        hop.setup({
            -- 跳转提示键位：使用 home row 字母（手指最自然的位置）
            keys = "asdghklqwertyuiopzxcvbnmfj",

            -- 大小写敏感
            case_insensitive = true,

            -- 跳转方向提示
            direction_labels = false,
        })

        local map = vim.keymap.set

        -- 两字符搜索跳转（最常用）
        map("n", "<leader>jc", function()
            hop.hint_char2({})
        end, { desc = "跳转到字符 (2 字符)" })

        -- 单词开头跳转
        map("n", "<leader>jw", function()
            hop.hint_words({})
        end, { desc = "跳转到单词" })

        -- 行首跳转
        map("n", "<leader>jl", function()
            hop.hint_lines({})
        end, { desc = "跳转到行" })

        -- 任意位置跳转（类似 EasyMotion 的 <leader><leader>w）
        map("n", "<leader>jj", function()
            hop.hint_patterns({}, "\\S")
        end, { desc = "跳转到任意非空字符" })

        -- 可视模式也支持跳转（扩展选区）
        map("v", "<leader>jc", function()
            hop.hint_char2({})
        end, { desc = "跳转到字符" })
        map("v", "<leader>jw", function()
            hop.hint_words({})
        end, { desc = "跳转到单词" })
        map("v", "<leader>jl", function()
            hop.hint_lines({})
        end, { desc = "跳转到行" })
    end,
}
