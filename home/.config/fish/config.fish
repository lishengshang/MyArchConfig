# ============================================================================
# ~/.config/fish/config.fish - Fish Shell 主入口
# ============================================================================
# 此文件保持极简, 所有逻辑都在 conf.d/ 自动按字母顺序加载:
#   00-env.fish           环境变量(fish 特有 + environment.d 兜底)
#   10-paths.fish         PATH 配置
#   20-abbreviations.fish 缩写(abbr, 按空格展开)
#   25-aliases.fish       别名(特殊场景)
#   35-pager.fish         Tab 补全分页器配色
#   40-fzf.fish           FZF 配置
#   50-tools.fish         工具初始化(starship/zoxide/atuin 等, 带缓存)
#   60-cnf.fish           command-not-found 处理
#
# 插件 conf.d(字母序在数字后): autopair / done / fzf / sponge
#
# 键绑定:       ~/.config/fish/functions/fish_user_key_bindings.fish
#               (fish 官方覆盖点: 第一个 prompt 时执行, 在 conf.d 之后,
#                可覆盖插件绑定 — 见 __fish_config_interactive.fish)
# 自定义命令补全: ~/.config/fish/completions/
# 自定义函数:     ~/.config/fish/functions/
# ============================================================================

# 此文件保持极简, 所有逻辑都在 conf.d/ 自动加载
