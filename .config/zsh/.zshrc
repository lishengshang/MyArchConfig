# =============================================================================
# $ZDOTDIR/.zshrc — 交互式 Zsh 主入口
# =============================================================================
# ZDOTDIR 由 ~/.zshenv 或 environment.d 设置为 ~/.config/zsh
#
# 加载顺序：
#   1. p10k instant prompt   （必须最先，零延迟提示符）
#   2. env.zsh               （交互式专属环境变量、history 设置）
#   3. options.zsh           （setopt 标志）
#   4. plugins.zsh           （Zinit + 全部插件）
#   5. completions.zsh       （compinit + fzf-tab 样式）
#   6. abbreviations.zsh     （zsh-abbr 缩写，类似 fish abbr）
#   7. aliases.zsh           （传统别名）
#   8. functions.zsh         （shell 函数）
#   9. bindings.zsh          （键绑定）
#  10. integrations.zsh      （direnv/mise/carapace/zoxide/cnf）
#  11. p10k.zsh              （主题配置）
# =============================================================================

# ---------------------------------------------------------------------------
# Stage 1: Powerlevel10k instant prompt
# 必须最先加载，在任何 stdout 输出之前
# ---------------------------------------------------------------------------
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
    source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ---------------------------------------------------------------------------
# Stage 2: 加载所有模块（按依赖顺序）
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
# Stage 3: Powerlevel10k 主题配置
# ---------------------------------------------------------------------------
[[ -f "$ZDOTDIR/p10k.zsh" ]] && source "$ZDOTDIR/p10k.zsh"

# ---------------------------------------------------------------------------
# 本地未跟踪的覆盖（如果存在则加载，不要进 git）
# ---------------------------------------------------------------------------
[[ -f "$ZDOTDIR/local.zsh" ]] && source "$ZDOTDIR/local.zsh"
