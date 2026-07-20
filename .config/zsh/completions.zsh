# =============================================================================
# completions.zsh - 补全子系统入口
# =============================================================================
# 职责：
#   1. fpath 归位（确保 $ZDOTDIR/completions 最优先，留给手写补全用）
#   2. 缓存目录 + completions/ 目录自检
#   3. fpath 指纹校验（版本或 fpath 变化时强制重建 dump）
#   4. 加载 zsh/complist
#   5. 调用 compinit（24h 复用 dump + 异步 zcompile）
#   6. source completion-styles.zsh   -- compinit 行为 zstyle
#   7. source completion-fzf-tab.zsh -- fzf-tab 样式与预览
#
# 外部工具（opencode/uv/gh/deno/...）的补全由 carapace 桥接统一提供，
# 不再为每个工具单独维护生成脚本。
# 依赖：env.zsh（LS_COLORS 已就绪）。
# =============================================================================

# --- fpath 归位（强制 $ZDOTDIR/completions 最优先）---
# plugins.zsh 加载 zinit 时可能调整过 fpath；这里重新归位确保用户补全覆盖
# zinit 的 zsh-users/zsh-completions 与 carapace 桥接。
fpath=(
    "$ZDOTDIR/completions"
    "$HOME/.local/share/zinit/completions"
    /usr/share/zsh/site-functions
    $fpath
)
typeset -U fpath                              # 去重，保留首次出现位置

# --- 缓存目录 + completions 目录自检 ---
typeset -g ZSH_COMP_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_COMP_CACHE_DIR" ]] || mkdir -p "$ZSH_COMP_CACHE_DIR"
[[ -d "$ZDOTDIR/completions" ]] || mkdir -p "$ZDOTDIR/completions"

zmodload zsh/complist

# --- fpath 指纹：版本或 fpath 变化时强制重建 dump ---
# compinit 内部已校验 ZSH_VERSION；这里额外校验 fpath 顺序（新增路径后自动失效）
typeset -g _zcompdump="$ZSH_COMP_CACHE_DIR/zcompdump"
typeset -g _comp_fp_file="$ZSH_COMP_CACHE_DIR/fingerprint"
typeset -g _comp_fp_current="${ZSH_VERSION}|${(j/:/)fpath}"
# ! -r 短路：文件不存在时不读 $(<file)，避免报错
if [[ ! -r "$_comp_fp_file" || "$(<"$_comp_fp_file")" != "$_comp_fp_current" ]]; then
    rm -f "$_zcompdump" "$_zcompdump.zwc"
    print -r -- "$_comp_fp_current" >! "$_comp_fp_file"
fi

# --- compinit（24h 复用 dump；命中则跳过 insecure-dir 检查）---
autoload -Uz compinit
if [[ -n ${_zcompdump}(#qN.mh-24) ]]; then
    compinit -C -d "$_zcompdump"
else
    compinit -d "$_zcompdump"
    # 异步把 dump 编译成 .zwc 字节码（mmap 友好，下次启动 ~5x 快）
    { [[ ! -f "$_zcompdump.zwc" || "$_zcompdump" -nt "$_zcompdump.zwc" ]] \
        && zcompile -R -- "$_zcompdump" } &!
fi
unset _zcompdump _comp_fp_file _comp_fp_current

# --- 补全行为样式 + fzf-tab 样式 ---
source "$ZDOTDIR/completion-styles.zsh"
source "$ZDOTDIR/completion-fzf-tab.zsh"
