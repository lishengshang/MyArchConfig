# =============================================================================
# integrations.zsh - 第三方工具集成
# =============================================================================
# 所有需要 init 脚本的工具集中管理（与 fish 的 _cached_init 策略对等：
# init 输出缓存到 ~/.cache/zsh/init/，工具二进制更新时自动重建，避免每次
# 启动都 fork 子进程生成脚本）。
# 加载顺序：compinit 之后；starship 必须在最后（覆盖 PROMPT）
# =============================================================================

# --- 缓存工具 init 输出（fish conf.d/50-tools.fish _cached_init 移植）---
# 用法：_zsh_cached_init <缓存名> <二进制路径> <生成命令...>
# 命中（二进制 mtime 未变）→ source 缓存；未命中 → 重新生成。
# 手动重建：rm -rf ~/.cache/zsh/init/
_zsh_cached_init() {
    local name="$1" bin="$2"; shift 2
    [[ -x "$bin" ]] || return 1
    local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/init/$name.zsh"
    if [[ ! -f "$cache" || "$bin" -nt "$cache" ]]; then
        mkdir -p "${cache:h}"
        "$@" > "$cache" 2>/dev/null || { rm -f "$cache"; return 1 }
        [[ -s "$cache" ]] || { rm -f "$cache"; return 1 }
    fi
    source "$cache"
}

# --- Zoxide（智能 cd，--cmd cd 接管原生 cd）---
(( $+commands[zoxide] )) && _zsh_cached_init zoxide "${commands[zoxide]}" zoxide init zsh --cmd cd

# --- mise（Python/Ruby/Go 等工具版本管理；Node 由 fnm 负责）---
# shims 模式：启动零 hook 开销（-13ms），工具按调用经 shim 解析版本。
# 实测 shim 单次调用开销 ~0ms（usage 1-2ms 级工具无感）。
# 注意：失去 precmd hook-env 自动重载（无 .mise.toml 项目时无影响）。
(( $+commands[mise] )) && eval "$(mise activate zsh --shims)"

# --- fnm（Node/npm/pi 版本管理；按目录读取 .node-version/.nvmrc）---
# fnm 放在 mise shims 之后初始化，确保 Node 由 fnm 而不是 mise/system node 接管。
if (( $+commands[fnm] )); then
    eval "$(fnm env --use-on-cd --shell zsh)"
    fnm use default --silent-if-unchanged >/dev/null 2>&1
fi

# --- direnv（项目级 .envrc 自动加载）---
(( $+commands[direnv] )) && _zsh_cached_init direnv "${commands[direnv]}" direnv hook zsh

# --- Atuin（神级历史搜索：接管 Ctrl+R）---
# 必须在 bindings.zsh 加载之后才生效（integrations 在最后，必赢 fzf）。
if (( $+commands[atuin] )); then
    # --disable-up-arrow：↑ 仍然走 zsh 原生 up-line-or-search（按前缀搜索），
    # atuin 只接管 Ctrl+R，避免和 zsh-autosuggestions 冲突
    _zsh_cached_init atuin "${commands[atuin]}" atuin init zsh --disable-up-arrow
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
    # 生成脚本缓存到 ~/.cache/zsh/init/（原为每次启动 source <(...) 进程替换）
    _zsh_cached_init carapace "${commands[carapace]}" carapace _carapace zsh
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
(( $+commands[starship] )) && _zsh_cached_init starship "${commands[starship]}" starship init zsh

# 清理 helper（避免污染全局命名空间）
unfunction _zsh_cached_init
