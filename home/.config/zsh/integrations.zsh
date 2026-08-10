# =============================================================================
# integrations.zsh - 第三方工具集成
# =============================================================================
# 所有需要 `eval "$(tool init zsh)"` 的工具集中管理
# 加载顺序：compinit 之后；starship 必须在最后（覆盖 PROMPT）
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

# --- Atuin（神级历史搜索：接管 Ctrl+R）---
# 必须在 bindings.zsh 加载之后才生效（integrations 在最后，必赢 fzf）。
if (( $+commands[atuin] )); then
    # --disable-up-arrow：↑ 仍然走 zsh 原生 up-line-or-search（按前缀搜索），
    # atuin 只接管 Ctrl+R，避免和 zsh-autosuggestions 冲突
    eval "$(atuin init zsh --disable-up-arrow)"
    # atuin init 内部已绑 ^r；这里仅做兜底（widget 存在时才绑，避免静默报错）
    (( ${+widgets[atuin-search]} )) && bindkey '^r' atuin-search
fi

# --- carapace（多 shell 通用补全引擎；输出非标准 fpath 文件，必须 source）---
# carapace 桥接 opencode/uv/gh/deno 等命令的补全，无需为每个工具单独维护生成脚本。
if (( $+commands[carapace] )); then
    export CARAPACE_BRIDGES='zsh,fish,bash,inshellisense'
    # 避免 carapace 覆盖 $ZDOTDIR/completions/ 下已有的手写补全（如 opencode/uv）。
    # carapace 的 bridge 对这些命令可能返回空候选，而手写补全更可靠。
    local _carapace_excludes
    _carapace_excludes=($ZDOTDIR/completions/_*(N:t))
    _carapace_excludes=(${_carapace_excludes#_})
    (( ${#_carapace_excludes} )) && export CARAPACE_EXCLUDES="${(j:,:)_carapace_excludes}"
    unset _carapace_excludes
    # 用 <() 进程替换，无缓存（carapace 启动 <50ms，可接受）
    source <(carapace _carapace zsh)
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
# mise 已接管多语言版本管理，conda 仅作为遗留环境兼容。
# 用 -d 提前过滤，避免每次启动都跑三次 [[ -r ]] 判定。
for _conda_init in \
    "$HOME/miniconda3/etc/profile.d/conda.sh" \
    "$HOME/anaconda3/etc/profile.d/conda.sh" \
    "$HOME/mambaforge/etc/profile.d/conda.sh"
do
    [[ -d "${_conda_init:h:h:h}" ]] || continue
    if [[ -r "$_conda_init" ]]; then
        source "$_conda_init"
        break
    fi
done
unset _conda_init

# --- Starship（提示符主题，跨 shell 通用）---
# 必须在最后加载：starship init 会注册 precmd hook 接管 PROMPT，
# 任何后续的 PROMPT 赋值都会覆盖它。
if (( $+commands[starship] )); then
    eval "$(starship init zsh)"
fi
