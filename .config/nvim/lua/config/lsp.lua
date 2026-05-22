-- lua/config/lsp.lua
-- LSP 快捷键（使用 Neovim 原生 vim.lsp.buf API，不依赖 mason 等插件）
-- 诊断显示配置

-- LspAttach autocmd：LSP 服务器附加到缓冲区时自动注册快捷键
vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
        local opts = { buffer = ev.buf }
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)     -- 跳转到定义
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)           -- 悬浮文档
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- 重命名
    end,
})

-- 诊断显示：行内虚拟文本 + 下划线
vim.diagnostic.config({
    virtual_text = true,
    underline = true,
})
