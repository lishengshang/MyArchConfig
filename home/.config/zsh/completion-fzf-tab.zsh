# =============================================================================
# completion-fzf-tab.zsh — fzf-tab 样式与预览
# =============================================================================
# fzf-tab 异步加载后会接管 Tab，本文件只是预先声明 zstyle（fzf-tab 启动时读取）。
# 加载顺序：由 completions.zsh 入口在 compinit 之后 source。
#
# 变量约定（fzf-tab 提供）：
#   $realpath  —— 当前候选的真实文件系统路径（用于 ls/cat/eza 等文件类预览）
#   $word      —— 当前候选词的字面值（用于 git log/kill/statusctl 等参数类预览）
# 所有预览都加 2>/dev/null 兜底，避免工具缺失时报错刷屏。
# =============================================================================

# --- fzf 通用：窗口外观 + 分组切换 ---
zstyle ':fzf-tab:*' fzf-flags '--height=40%' '--layout=reverse' '--border=rounded' '--info=inline'
zstyle ':fzf-tab:*' switch-group ',' '.'

# --- 行为增强 ---
zstyle ':fzf-tab:*' continuous-trigger '/'             # fzf 内按 / 直接进入子目录
zstyle ':fzf-tab:*' accept-line space                   # 选中后回车接受补全并加空格，不直接执行
zstyle ':fzf-tab:*' show-group full                     # 按 tag 分组（commands/branches/files...）
zstyle ':fzf-tab:*' single-group color header           # 单组时显示彩色 header
zstyle ':fzf-tab:*' prefix ''                           # 去掉候选前的 -- / - 前缀
zstyle ':fzf-tab:*' fzf-bindings 'ctrl-space:toggle'    # Ctrl+Space 多选切换
# fzf 初始查询：用用户已输入的字作为 prefill（git a<Tab> 时 fzf 查询框预填 "a"）。
# 默认 (prefix input first) 里的 input 会把整段已输入路径塞进查询框，
# 导致 `cat ~/.config/scripts<Tab>` 无法搜索目录内文件；改用 prefix，
# 只取候选的公共前缀（如 `git a<Tab>` 的公共前缀仍是 `a`）。
zstyle ':fzf-tab:*' query-string prefix

# ============================================================================
# 预览：按主题分组
# ============================================================================

# --- 目录预览（cd / zoxide / ls 系列）---
zstyle ':fzf-tab:complete:cd:*'           fzf-preview 'eza -1 --color=always --icons --group-directories-first $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*'   fzf-preview 'eza -1 --color=always --icons --group-directories-first $realpath 2>/dev/null || ls $realpath'
zstyle ':fzf-tab:complete:(\\|*/|)ls:*'   fzf-preview 'eza -1 --color=always --icons $realpath 2>/dev/null || ls $realpath'

# --- 文件预览（cat / nvim）---
zstyle ':fzf-tab:complete:(\\|*/|)cat:*'  fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:nvim:*'         fzf-preview 'bat --color=always --style=numbers --line-range=:500 $realpath 2>/dev/null'

# --- Git 预览 ---
zstyle ':fzf-tab:complete:git-(add|diff|restore|show|stash):*' \
    fzf-preview 'git diff --color=always $word 2>/dev/null | head -100'
zstyle ':fzf-tab:complete:git-checkout:*' \
    fzf-preview 'git log --color=always --oneline --graph $word 2>/dev/null | head -20'
zstyle ':fzf-tab:complete:git-log:*' \
    fzf-preview 'git log --color=always --oneline --graph 2>/dev/null | head -50'

# --- 进程 / systemd / man ---
zstyle ':fzf-tab:complete:kill:*'         fzf-preview 'procs --pid=$word --color=always 2>/dev/null || ps -p $word -o cmd'
zstyle ':fzf-tab:complete:systemctl-*:*'  fzf-preview 'SYSTEMD_COLORS=1 systemctl status $word'
zstyle ':fzf-tab:complete:man:*'          fzf-preview 'man $word 2>/dev/null | head -50'

# --- 环境变量（${(P)word} 间接取值）---
zstyle ':fzf-tab:complete:(-command-|-parameter-|-brace-parameter-|export|unset|expand):*' \
    fzf-preview 'echo ${(P)word}'
