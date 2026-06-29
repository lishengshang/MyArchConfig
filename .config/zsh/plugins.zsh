# =============================================================================
# plugins.zsh — Zinit 插件管理
# =============================================================================
# 加载策略：
#   - 同步：instant prompt 主题、abbr（在 abbreviations.zsh 之前）
#   - 异步 (wait lucid)：补全、语法高亮、自动建议、fzf-tab、forgit
#
# compinit 由 fast-syntax-highlighting 的 atinit 钩子调用（zicompinit）。
# completions.zsh 只放 zstyle，不再重复调用 compinit。
#
# 工具策略：fd/bat/eza/rg/sd/delta/hyperfine/dust/procs/btop/fzf 等
# 一律来自 pacman（更新由系统统一管理），不再 zinit gh-r 下载。
# =============================================================================

# --- fpath 设置（必须在 compinit 之前；用户补全放最前以覆盖 carapace 桥接）---
fpath=(
    "$ZDOTDIR/completions"
    "$HOME/.local/share/zinit/completions"
    /usr/share/zsh/site-functions
    $fpath
)

# --- 安装 Zinit（自举）---
ZINIT_HOME="$HOME/.local/share/zinit/zinit.git"
if [[ ! -f "$ZINIT_HOME/zinit.zsh" ]]; then
    print -P "%F{33}Installing Zinit...%f"
    command mkdir -p "$(dirname "$ZINIT_HOME")"
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME" --depth=1 \
        && print -P "%F{34}✓ Zinit installed%f" \
        || print -P "%F{196}✗ Zinit clone failed%f"
fi
source "$ZINIT_HOME/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# --- Zinit annexes ---
# 仅保留 as-monitor（监控插件更新）和 patch-dl（补丁下载）。
# bin-gem-node / rust 已废弃：工具一律来自 pacman，不再用 zinit ice bin=/gem=/rust= 装二进制。
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-patch-dl

# --- Powerlevel10k（同步，instant prompt 依赖）---
zinit ice depth=1
zinit light romkatv/powerlevel10k

# --- zsh-abbr（同步：abbreviations.zsh 在 source 时需要 abbr 命令存在）---
zinit light olets/zsh-abbr

# ============================================================================
# 异步加载（启动后约 100ms 才注入，不影响 prompt 出现速度）
# ============================================================================

# --- 核心增强 ---
# compinit 由 completions.zsh 同步完成；这里 fsh 的 atinit 只重放补全队列。
# autosuggestions 键绑定：
#   ^[  (Ctrl+Space)  接受整条建议
#   ^[^M (Alt+Enter)  接受整条建议（备用，避开 emacs 的 ^Y yank）
#   ^[[C (Right)      接受整条建议（右箭头）
zinit wait lucid light-mode for \
    atinit"zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start; bindkey '^ ' autosuggest-accept; bindkey '^[^M' autosuggest-accept; bindkey '^[[C' autosuggest-accept" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

# --- zsh-history-substring-search（↑/↓ 按子串搜索历史）---
# atload 里覆盖 bindings.zsh 的 up-line-or-search：现在 ↑/↓ 走子串搜索。
# 必须在 autosuggestions 之后加载，绑定才会赢。
zinit ice wait lucid atload"bindkey '^[[A' history-substring-search-up; bindkey '^[[B' history-substring-search-down; bindkey '^P' history-substring-search-up; bindkey '^N' history-substring-search-down"
zinit light zsh-users/zsh-history-substring-search

# --- fzf-tab（Tab 补全 fzf 化；必须在 compinit 之后） ---
zinit wait lucid for Aloxaf/fzf-tab

# --- forgit（fzf + git 交互）---
zinit wait lucid for wfxr/forgit
