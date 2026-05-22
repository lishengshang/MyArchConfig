-- lua/plugins/autopairs.lua
-- 自动配对：输入左括号/引号时自动补全右半部分

return {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
        local npairs = require("nvim-autopairs")

        npairs.setup({
            -- 启用 Treesitter 感知（安装了 treesitter 时生效，未安装时无副作用）
            check_ts = true,

            -- 在这些文件类型中禁用
            disable_filetype = { "TelescopePrompt", "spectre_panel" },

            -- 快速配对：连续输入时跳过右半部分（例如输入完 "hello" 再输入 " 会跳过而不是插入两个引号）
            fast_wrap = {
                map = "<M-e>",
                chars = { "{", "[", "(", '"', "'" },
                pattern = [=[[%'%"%>%]%)%}%,]]=],
                end_key = "$",
                keys = "qwertyuiopzxcvbnmasdfghjkl",
                check_comma = true,
                manual_position = true,
                highlight = "Search",
                highlight_grey = "Comment",
            },
        })

        -- 与 nvim-cmp 集成：补全确认时自动处理配对符号，避免插入多余的括号/引号
        local ok_cmp, cmp = pcall(require, "cmp")
        if ok_cmp then
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end
    end,
}
