# ============================================================================
# 35-pager-matugen.fish - Fish 颜色（matugen 自动生成）
# ============================================================================
# 由 ~/.config/matugen/templates/fish-pager.fish 生成
# 手动修改会被下次 matugen 运行覆盖
#
# 设计：Material You 设计系统语义化颜色映射
#   - fish 4.8.1 的 pager 只有 13 个有效颜色变量（highlight.rs 源码确认）:
#     基础组 prefix/completion/description/background/progress
#     secondary_* = 隔行斑马纹（row % 2 != 0 的行，不是"选项列"）
#     selected_*  = 当前选中行
#     ⚠️ 不存在 tertiary_* 变量 —— 设置会被静默忽略
#     ⚠️ 不存在 fish_pager_color_search_match —— pager 搜索高亮用的是
#        fish_color_search_match（fish_color_search_match 同时用于历史
#        搜索匹配和 pager 选中行兜底）
#   - 命令行语法色（fish_color_*）与 pager 一起随壁纸联动，
#     保持 starship / kitty / fuzzel 等 Material You 一致性
#   - 关键1：背景色值必须用 --background= 前缀，否则被当前景色（隐形）
#   - 关键2：所有 # 开头的颜色值必须加引号，否则 # 被 fish 当注释符
# ============================================================================

if status is-interactive
    # --- 命令行语法高亮（Material You 语义映射） ---
    set -g fish_color_normal '{{colors.on_surface.default.hex}}'
    set -g fish_color_command '{{colors.primary.default.hex}}'
    set -g fish_color_builtin '{{colors.primary.default.hex}}'
    set -g fish_color_function '{{colors.primary.default.hex}}'
    set -g fish_color_keyword '{{colors.primary.default.hex}}'
    set -g fish_color_param '{{colors.on_surface.default.hex}}'
    set -g fish_color_option '{{colors.tertiary.default.hex}}'
    set -g fish_color_quote '{{colors.secondary.default.hex}}'
    set -g fish_color_redirection '{{colors.tertiary.default.hex}}'
    set -g fish_color_end '{{colors.on_surface_variant.default.hex}}'
    set -g fish_color_operator '{{colors.tertiary.default.hex}}'
    set -g fish_color_escape '{{colors.tertiary.default.hex}}'
    set -g fish_color_comment '{{colors.on_surface_variant.default.hex}}'
    set -g fish_color_error '{{colors.error.default.hex}}'
    set -g fish_color_valid_path '{{colors.on_surface.default.hex}}' --underline
    set -g fish_color_autosuggestion '{{colors.outline.default.hex}}'
    set -g fish_color_selection '{{colors.on_surface.default.hex}}' '--background={{colors.surface_container_high.default.hex}}' --bold
    set -g fish_color_search_match '{{colors.on_surface.default.hex}}' '--background={{colors.secondary_container.default.hex}}' --bold

    # --- pager: 进度条（顶部标题行）---
    set -g fish_pager_color_progress '{{colors.primary.default.hex}}'

    # --- 基础组（所有行的默认样式）---
    set -g fish_pager_color_prefix '{{colors.primary.default.hex}}'
    set -g fish_pager_color_completion '{{colors.on_surface.default.hex}}'
    set -g fish_pager_color_background ''
    set -g fish_pager_color_description '{{colors.on_surface_variant.default.hex}}'

    # --- 斑马纹（偶数行 secondary_*，行号 row % 2 != 0 触发）---
    # 注意: secondary_* 不是"选项列"，而是隔行条纹，用于长列表可读性
    set -g fish_pager_color_secondary_prefix '{{colors.tertiary.default.hex}}'
    set -g fish_pager_color_secondary_completion '{{colors.on_surface.default.hex}}'
    set -g fish_pager_color_secondary_background ''
    set -g fish_pager_color_secondary_description '{{colors.on_surface_variant.default.hex}}'

    # --- 选中行（高亮当前项，即"选框"）---
    # 用 primary（亮色）做背景，on_primary（深色）做前景，对比强烈、辨识度高
    set -g fish_pager_color_selected_background '--background={{colors.primary.default.hex}}'
    set -g fish_pager_color_selected_prefix '{{colors.on_primary.default.hex}}' --bold
    set -g fish_pager_color_selected_completion '{{colors.on_primary.default.hex}}' --bold
    set -g fish_pager_color_selected_description '{{colors.on_primary.default.hex}}'
end
