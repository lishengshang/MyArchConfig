# ============================================================================
# 35-pager-matugen.fish - Fish Tab 补全分页器配色（matugen 自动生成）
# ============================================================================
# 由 ~/.config/matugen/templates/fish-pager.fish 生成
# 手动修改会被下次 matugen 运行覆盖
#
# 设计：Material You 设计系统语义化颜色映射
#   - 三级层级（command / option / file）用 primary / tertiary / secondary
#     三种色调区分，符合 Material You 的"色彩角色"原则
#   - 选中行用 primary（亮色）做背景 + on_primary（深色）做前景，
#     这是 fzf / VS Code / JetBrains 等现代 UI 的选中高亮标准做法。
#     关键1：背景色值必须用 --background= 前缀，否则被当前景色（隐形）
#     关键2：所有 #开头的颜色值必须加引号，否则 # 被 fish 当注释符
#   - 描述用 on_surface_variant（次要文字色），让信息层次清晰
#   - 颜色随壁纸动态变化，与 starship / kitty / fuzzel 等保持一致
# ============================================================================

if status is-interactive
    # --- 进度条（顶部标题行）---
    set -g fish_pager_color_progress '{{colors.primary.default.hex}}'

    # --- 第一组（command / builtin）---
    set -g fish_pager_color_prefix '{{colors.primary.default.hex}}'
    set -g fish_pager_color_completion '{{colors.on_surface.default.hex}}'
    set -g fish_pager_color_background ''
    set -g fish_pager_color_description '{{colors.on_surface_variant.default.hex}}'

    # --- 第二组（option）---
    set -g fish_pager_color_secondary_prefix '{{colors.tertiary.default.hex}}'
    set -g fish_pager_color_secondary_completion '{{colors.on_surface.default.hex}}'
    set -g fish_pager_color_secondary_background ''
    set -g fish_pager_color_secondary_description '{{colors.on_surface_variant.default.hex}}'

    # --- 第三组（file / variable / alias）---
    set -g fish_pager_color_tertiary_prefix '{{colors.secondary.default.hex}}'
    set -g fish_pager_color_tertiary_completion '{{colors.on_surface.default.hex}}'
    set -g fish_pager_color_tertiary_background ''
    set -g fish_pager_color_tertiary_description '{{colors.on_surface_variant.default.hex}}'

    # --- 选中行（高亮当前项，即"选框"）---
    # 用 primary（亮色）做背景，on_primary（深色）做前景，对比强烈、辨识度高
    set -g fish_pager_color_selected_background '--background={{colors.primary.default.hex}}'
    set -g fish_pager_color_selected_prefix '{{colors.on_primary.default.hex}}' --bold
    set -g fish_pager_color_selected_completion '{{colors.on_primary.default.hex}}' --bold
    set -g fish_pager_color_selected_description '{{colors.on_primary.default.hex}}'

    # --- 搜索匹配高亮（pager 内按 / 搜索时）---
    set -g fish_pager_color_search_match '--background={{colors.secondary.default.hex}}' --bold
end
