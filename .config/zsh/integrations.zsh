# =============================================================================
# integrations.zsh — 第三方工具集成
# =============================================================================
# 所有需要 `eval "$(tool init zsh)"` 的工具集中管理
# 加载顺序：compinit 之后，p10k 之前
# =============================================================================

# --- Zoxide（智能 cd，--cmd cd 接管原生 cd）---
if (( $+commands[zoxide] )); then
    eval "$(zoxide init zsh --cmd cd)"
fi

# --- mise（统一版本管理器：Node/Python/Ruby/Go/...；替代 fnm/nvm/pyenv）---
if (( $+commands[mise] )); then
    eval "$(mise activate zsh)"
fi

# --- direnv（项目级 .envrc 自动加载）---
if (( $+commands[direnv] )); then
    eval "$(direnv hook zsh)"
fi

# --- uv shell 补全（按日缓存，避免每次启动 fork）---
if (( $+commands[uv] )); then
    typeset -g _uv_comp_cache="${XDG_CACHE_HOME:-$HOME/.cache}/uv/zsh-completion.zsh"
    if [[ ! -s "$_uv_comp_cache" ]] \
       || [[ $(date -r "$_uv_comp_cache" +%j 2>/dev/null) != $(date +%j) ]] \
       || [[ "$_uv_comp_cache" -ot "$commands[uv]" ]]; then
        mkdir -p "${_uv_comp_cache:h}"
        if ! uv generate-shell-completion zsh > "$_uv_comp_cache" 2>/dev/null; then
            rm -f "$_uv_comp_cache"
        fi
    fi
    [[ -s "$_uv_comp_cache" ]] && source "$_uv_comp_cache"
    unset _uv_comp_cache
fi

# --- Atuin（神级历史搜索：接管 Ctrl+R）---
# 必须在 bindings.zsh 加载之后才生效（integrations 在最后，必赢 fzf）。
if (( $+commands[atuin] )); then
    # --disable-up-arrow：↑ 仍然走 zsh 原生 up-line-or-search（按前缀搜索），
    # atuin 只接管 Ctrl+R，避免和 zsh-autosuggestions 冲突
    eval "$(atuin init zsh --disable-up-arrow)"
    # atuin init 内部已绑 ^r；这里仅做兜底（widget 存在时才绑，避免静默报错）
    (( ${+widgets[atuin-search]} )) && bindkey '^r' atuin-search
fi

# ============================================================================
# carapace（多 shell 通用补全引擎）
# ============================================================================
# 用户在 $ZDOTDIR/completions 下的手写补全已通过 fpath 优先于 carapace 桥接
# （plugins.zsh 把 $ZDOTDIR/completions 放在 fpath 最前），不再需要手动 compdef。
# ============================================================================
if (( $+commands[carapace] )); then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    typeset -g _carapace_cache="${XDG_CACHE_HOME:-$HOME/.cache}/carapace/zsh.ps1"
    # 缓存条件：不存在 / 为空 / 不是今天的
    if [[ ! -s "$_carapace_cache" ]] \
       || [[ $(date -r "$_carapace_cache" +%j 2>/dev/null) != $(date +%j) ]]; then
        mkdir -p "${_carapace_cache:h}"
        if ! carapace _carapace zsh > "$_carapace_cache" 2>/dev/null; then
            rm -f "$_carapace_cache"
        fi
    fi
    [[ -s "$_carapace_cache" ]] && source "$_carapace_cache"
    unset _carapace_cache
fi

# --- command-not-found handler（Arch pkgfile 集成）---
if [[ -f /usr/share/doc/pkgfile/command-not-found.zsh ]]; then
    source /usr/share/doc/pkgfile/command-not-found.zsh
fi

# --- Broot ---
[[ -f "$HOME/.config/broot/launcher/zsh/br" ]] && source "$HOME/.config/broot/launcher/zsh/br"

# --- bun 补全 ---
[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# --- Conda/Mamba（如果存在）---
for _conda_init in \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/anaconda3/etc/profile.d/conda.sh" \
    "$HOME/mambaforge/etc/profile.d/conda.sh"
do
    if [[ -r "$_conda_init" ]]; then
        source "$_conda_init"
        break
    fi
done
unset _conda_init
