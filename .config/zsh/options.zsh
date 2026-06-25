# =============================================================================
# options.zsh — Zsh 选项（setopt / unsetopt）
# =============================================================================

# --- 目录导航 ---
setopt AUTO_CD                  # 输入目录名自动 cd
setopt AUTO_PUSHD               # cd 时压入目录栈
setopt PUSHD_IGNORE_DUPS        # 栈中去重
setopt PUSHD_MINUS              # cd -2 走栈中第二个
setopt PUSHD_SILENT             # 静默 pushd

# --- Globbing ---
setopt EXTENDED_GLOB            # 支持 #, ~, ^
setopt GLOB_DOTS                # glob 包含隐藏文件
setopt NUMERIC_GLOB_SORT        # 按数字排序而非字典序
unsetopt NOMATCH                # 无匹配时不报错（透传到命令）
unsetopt CASE_GLOB              # glob 不区分大小写

# --- History ---
setopt EXTENDED_HISTORY         # 时间戳
setopt HIST_IGNORE_DUPS         # 连续重复不记录
setopt HIST_IGNORE_ALL_DUPS     # 历史中所有重复都删除
setopt HIST_IGNORE_SPACE        # 空格开头不记录
setopt HIST_REDUCE_BLANKS       # 压缩空格
setopt HIST_VERIFY              # !! 不立即执行，先显示
setopt HIST_EXPIRE_DUPS_FIRST   # 历史满时先删重复
setopt HIST_FIND_NO_DUPS        # 搜索时不显示重复
setopt SHARE_HISTORY            # 跨会话共享
setopt HIST_FCNTL_LOCK          # 锁文件防多写入冲突

# --- 任务控制 ---
setopt NOTIFY                   # 后台任务立刻通知
setopt LONG_LIST_JOBS           # jobs 默认 -l
unsetopt BG_NICE                # 后台任务不降优先级
unsetopt HUP                    # 退出时不杀后台
unsetopt CHECK_JOBS             # 退出时不警告后台任务

# --- 交互体验 ---
setopt INTERACTIVE_COMMENTS     # 交互式允许 # 注释
setopt RC_QUOTES                # '' 转义单引号
setopt COMBINING_CHARS          # Unicode 组合字符正确显示
unsetopt FLOW_CONTROL           # 禁用 Ctrl+S/Q（释放给应用用）
unsetopt BEEP                   # 关闭蜂鸣

# --- 补全相关 ---
setopt ALWAYS_TO_END            # 补全到结尾后光标到结尾
setopt AUTO_MENU                # 第二次 Tab 显示菜单
setopt AUTO_LIST                # 多个候选时列出
setopt COMPLETE_IN_WORD         # 词中间也能补全
unsetopt MENU_COMPLETE          # 不自动选第一个

# --- 错误处理 ---
setopt NO_CLOBBER               # > 不覆盖已存在文件（用 >| 强制）
                                # 解除：unsetopt clobber 或 >| file

# --- Shell hooks（必须 autoload） ---
autoload -Uz add-zsh-hook
autoload -Uz compinit
