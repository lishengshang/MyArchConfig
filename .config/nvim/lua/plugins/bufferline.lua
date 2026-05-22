-- lua/plugins/bufferline.lua
-- 顶部标签栏：显示打开的文件缓冲区，支持点击切换和快捷键导航
return {
    "akinsho/bufferline.nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "catppuccin/nvim",
    },
    config = function()
        local bufferline = require("bufferline")
        bufferline.setup({
            options = {
                -- 显示模式：按标签页顺序排列
                mode = "buffers",
                -- 编号从 1 开始，方便 <leader>b1 / <leader>b2 切换
                numbers = "ordinal",
                -- 左侧分隔符（兼容 nvim-tree 展开时自动偏移）
                indicator = {
                    style = "icon",
                    icon = "▎",
                },
                -- 右侧显示关闭按钮
                close_command = "bdelete! %d",
                right_mouse_command = "bdelete! %d",
                left_mouse_command = "buffer %d",
                -- 缓冲区已修改时显示圆点标记
                modified_icon = "●",
                -- 诊断信息（错误/警告）显示在标签上
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(count, level)
                    local icon = level:match("error") and "  " or "  "
                    return icon .. count
                end,
                -- 关闭图标
                buffer_close_icon = "✕",
                -- 启用悬停提示
                hover = {
                    enabled = true,
                    delay = 200,
                    reveal = { "close" },
                },
                -- 排序：保持打开顺序
                sort_by = "insert_at_end",
            },
        })

        -- 加载 catppuccin bufferline 高亮组
        require("catppuccin").setup({
            flavour = "mocha",
            integrations = {
                bufferline = true,
            },
        })
        -- 重新应用主题以刷新 bufferline 颜色
        vim.cmd.colorscheme("catppuccin")

        -- 快捷键
        local map = vim.keymap.set

        -- Alt+, 前一个缓冲区
        map("n", "<A-,>", "<Cmd>BufferLineCyclePrev<CR>", { desc = "上一个标签" })
        -- Alt+. 后一个缓冲区
        map("n", "<A-.>", "<Cmd>BufferLineCycleNext<CR>", { desc = "下一个标签" })
        -- Leader + bd 关闭当前缓冲区
        map("n", "<leader>bd", "<Cmd>bdelete<CR>", { desc = "关闭当前缓冲区" })
        -- Alt+数字 跳转到指定编号的缓冲区（需要 numbers = "ordinal"）
        for i = 1, 9 do
            map("n", "<A-" .. i .. ">", "<Cmd>BufferLineGoToBuffer " .. i .. "<CR>", { desc = "跳转到标签 " .. i })
        end
        -- Leader + bp 使用 Telescope 快速选择缓冲区
        map("n", "<leader>bp", "<Cmd>BufferLinePick<CR>", { desc = "选择缓冲区" })
        -- Leader + bf 关闭当前缓冲区后聚焦左侧（比 bdelete 更智能，避免窗口布局跳变）
        map("n", "<leader>bf", "<Cmd>BufferLinePickClose<CR>", { desc = "选择要关闭的缓冲区" })
    end,
}
