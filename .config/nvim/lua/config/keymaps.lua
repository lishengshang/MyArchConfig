-- lua/config/keymaps.lua
-- 通用快捷键映射（不依赖任何插件）

-- 文件操作
vim.keymap.set("n", "<leader>w", ":w<CR>", { desc = "保存文件" })
vim.keymap.set("n", "<leader>q", ":q<CR>", { desc = "退出窗口" })
vim.keymap.set("n", "<leader>wq", ":wq<CR>", { desc = "保存并退出" })
vim.keymap.set("n", "<leader>Q", ":q!<CR>", { desc = "强制退出不保存" })
vim.keymap.set("n", "<leader>h", ":nohlsearch<CR>", { desc = "清除搜索高亮" })

-- 分屏导航
vim.keymap.set("n", "<C-h>", "<C-w>h", { desc = "切换到左侧分屏" })
vim.keymap.set("n", "<C-j>", "<C-w>j", { desc = "切换到下方分屏" })
vim.keymap.set("n", "<C-k>", "<C-w>k", { desc = "切换到上方分屏" })
vim.keymap.set("n", "<C-l>", "<C-w>l", { desc = "切换到右侧分屏" })

-- 快捷键改变

-- 为kd和下面的translate.lua适配的 最小化配置 注释掉
-- -- 更智能的浮动窗口关闭
-- vim.keymap.set("n", "<leader>c", function()
--     local closed_count = 0
    
--     for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
--         local config = vim.api.nvim_win_get_config(win)
        
--         -- 判断是浮动窗口
--         if config and config.relative ~= "" then
--             -- 可选：排除某些特殊的浮动窗口
--             local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
            
--             -- 排除 trouble.nvim 等不想关闭的窗口
--             if not bufname:match("trouble") then
--                 vim.api.nvim_win_close(win, false)
--                 closed_count = closed_count + 1
--             end
--         end
--     end
    
--     if closed_count > 0 then
--         vim.notify("已关闭 " .. closed_count .. " 个浮动窗口", vim.log.levels.INFO)
--     end
-- end, { desc = "关闭所有浮动窗口" })

-- -- 双击 ESC：先尝试关闭浮动窗口，没有则正常使用 ESC
-- vim.keymap.set("n", "<ESC><ESC>", function()
--     local has_floating = false
    
--     -- 检查是否有浮动窗口
--     for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
--         local config = vim.api.nvim_win_get_config(win)
--         if config and config.relative ~= "" then
--             has_floating = true
--             break
--         end
--     end
    
--     if has_floating then
--         -- 有浮动窗口：关闭所有浮动窗口
--         for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
--             local config = vim.api.nvim_win_get_config(win)
--             if config and config.relative ~= "" then
--                 vim.api.nvim_win_close(win, false)
--             end
--         end
--     else
--         -- 没有浮动窗口：正常执行 ESC 功能（取消高亮等）
--         vim.cmd("nohlsearch")
--     end
-- end, { desc = "双击ESC：关闭浮动窗口或取消搜索高亮" })

-- C 语言一键编译运行
vim.keymap.set("n", "<leader>r", function()
    local file = vim.fn.expand("%")
    local output = vim.fn.expand("%:r")
    vim.cmd("w")
    local compile = "gcc " .. file .. " -o " .. output
    local result = vim.fn.system(compile)
    if vim.v.shell_error ~= 0 then
        print("编译失败:\n" .. result)
        return
    end
    vim.cmd("split | terminal ./" .. output)
end, { desc = "Run C program" })
