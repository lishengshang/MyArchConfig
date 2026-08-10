# =============================================================================
# $ZDOTDIR/.zshrc - 交互式 Zsh 主入口
# =============================================================================
# ZDOTDIR 由 ~/.zshenv 或 environment.d 设置为 ~/.config/zsh
#
# 加载顺序：
#   1. env.zsh               （交互式专属环境变量、history 设置）
#   2. options.zsh           （setopt 标志）
#   3. plugins.zsh           （Zinit + 全部插件）
#   4. completions.zsh       （补全子系统入口：fpath 之外的 compinit + 子模块）
#     ├─ completion-styles.zsh  （compinit zstyle：菜单、匹配、颜色、分组）
#     └─ completion-fzf-tab.zsh （fzf-tab 样式与预览）
#   5. abbreviations.zsh     （zsh-abbr 缩写，类似 fish abbr）
#   6. aliases.zsh           （传统别名）
#   7. functions.zsh         （shell 函数）
#   8. bindings.zsh          （键绑定）
#   9. integrations.zsh      （starship/direnv/mise/carapace/zoxide/cnf）
# =============================================================================

# ---------------------------------------------------------------------------
# 加载所有模块（按依赖顺序）
# ---------------------------------------------------------------------------
for module in \
    env.zsh \
    options.zsh \
    plugins.zsh \
    completions.zsh \
    abbreviations.zsh \
    aliases.zsh \
    functions.zsh \
    bindings.zsh \
    integrations.zsh
do
    source "$ZDOTDIR/$module"
done

# ---------------------------------------------------------------------------
# 本地未跟踪的覆盖（如果存在则加载，不要进 git）
# ---------------------------------------------------------------------------
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
