# =============================================================================
# plugins.zsh — Zinit 插件管理
# =============================================================================
# 加载策略：
#   - 即时加载 (synchronous)：关键插件、需要在 compinit 前就绪的
#   - 异步加载 (wait lucid)：装饰性、补全增强、版本管理
#   - GitHub Release 二进制 (gh-r)：CLI 工具
#
# compinit 在 completions.zsh 中显式调用一次
# =============================================================================

# --- fpath 设置（必须在 compinit 之前）---
fpath=("$HOME/.local/share/zinit/completions" $fpath)
fpath=("$HOME/.config/zsh/completions" $fpath)
fpath=(/usr/share/zsh/site-functions $fpath)

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

# --- Zinit annexes（必需）---
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust

# --- Oh-My-Zsh 库（同步，体积小、被其他插件依赖）---
zinit light-mode for \
    OMZL::clipboard.zsh \
    OMZL::history.zsh \
    OMZL::key-bindings.zsh \
    OMZL::completion.zsh

# --- Powerlevel10k（同步，instant prompt 依赖）---
zinit ice depth=1
zinit light romkatv/powerlevel10k

# --- zsh-abbr（同步，提供 fish 风格 abbreviation）---
# 必须同步加载，否则 abbr 命令在 abbreviations.zsh 执行时不存在
zinit light olets/zsh-abbr

# ============================================================================
# 异步加载（启动后约 100ms 才注入，不影响 prompt 出现速度）
# ============================================================================

# --- 核心增强（自动建议、语法高亮、历史搜索）---
zinit wait lucid light-mode for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start; bindkey '^ ' autosuggest-accept; bindkey '^Y' autosuggest-accept; bindkey '^[[C' forward-char" \
        zsh-users/zsh-autosuggestions \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions \
    zdharma-continuum/history-search-multi-word

# --- fzf-tab（增强 Tab 补全为 fzf 界面）---
zinit wait lucid for Aloxaf/fzf-tab

# --- forgit（fzf + git 交互）---
zinit wait lucid for wfxr/forgit

# --- fnm（Node.js 版本管理，异步）---
zinit wait lucid as"command" from"gh-r" \
    atclone"./fnm completions --shell zsh > _fnm" \
    atpull"%atclone" \
    atload'eval "$(fnm env --use-on-cd --shell zsh)"' \
    for Schniz/fnm

# ============================================================================
# CLI 工具（从 GitHub Releases 异步下载到 ~/.local/share/zinit/）
# 优势：版本可控、不依赖 pacman、卸载干净
# ============================================================================
zinit wait lucid as"command" from"gh-r" for \
    mv"fd* -> fd" pick"fd/fd"           sharkdp/fd \
    mv"bat* -> bat" pick"bat/bat"       sharkdp/bat \
    mv"eza* -> eza" pick"eza/eza"       eza-community/eza \
    mv"ripgrep* -> rg" pick"rg/rg"      BurntSushi/ripgrep \
    pick"sd"                             chmln/sd \
    mv"delta* -> delta" pick"delta/delta" dandavison/delta \
    mv"hyperfine* -> hyperfine" pick"hyperfine/hyperfine" sharkdp/hyperfine \
    mv"dust* -> dust" pick"dust/dust"   bootandy/dust \
    mv"procs* -> procs" pick"procs/procs" dalance/procs \
    mv"btm* -> btm" pick"btm/btm"       ClementTsang/bottom

# --- fzf 本体 ---
zinit wait lucid as"program" from"gh-r" pick"fzf" for junegunn/fzf
