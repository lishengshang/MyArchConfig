-- lua/plugins/mason.lua
-- LSP 安装器 + 配置桥接
-- mason：管理 LSP/DAP/Linter 安装
-- mason-lspconfig：自动配置已安装的 LSP 服务器

return {
    -- Mason：LSP 包管理器
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup({
                ui = {
                    border = "rounded",
                },
            })
        end,
    },

    -- Mason-LSP 配置桥接
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "hrsh7th/cmp-nvim-lsp" },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            -- lua_ls 特殊配置：将 vim 识别为全局变量，避免误报
            vim.lsp.config("lua_ls", {
                capabilities = capabilities,
                settings = {
                    Lua = {
                        diagnostics = { globals = { "vim" } },
                    },
                },
            })

            -- clangd 特殊配置：UTF-8 偏移编码（Neovim 默认 UTF-8，clangd 默认 UTF-16）
            vim.lsp.config("clangd", {
                capabilities = capabilities,
                offset_encoding = "utf-8",
            })

            require("mason-lspconfig").setup({
                automatic_installation = true,
                ensure_installed = {
                  "lua_ls",   -- Lua
--                    "pyright",  -- Python
--                    "ts_ls",    -- TypeScript/JavaScript
                    "clangd",   -- C/C++
                },
                handlers = {
                    function(server)
                        if server ~= "lua_ls" and server ~= "clangd" then
                            vim.lsp.config(server, {
                                capabilities = capabilities,
                            })
                        end
                        vim.lsp.enable(server)
                    end,
                },
            })
        end,
    },
}
