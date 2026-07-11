# ============================================================================
# 50-tools.fish — 工具初始化（交互式 shell 专属）
# ============================================================================
# 所有需要 init 的工具集中在这里
# command -q 检查避免工具不存在时报错
# ============================================================================

if status is-interactive
    # --- Starship 提示符 ---
    if command -q starship
        starship init fish | source
    end

    # --- Zoxide 智能 cd（替代 cd） ---
    if command -q zoxide
        zoxide init fish --cmd cd | source
    end

    # --- uv shell 补全 ---
    if command -q uv
        uv generate-shell-completion fish 2>/dev/null | source
    end

    # --- fnm Node.js 版本管理 ---
    if command -q fnm
        fnm env --use-on-cd --shell fish | source
    end

    # --- mise 统一版本管理器（Node/Python/Ruby/Go） ---
    if command -q mise
        mise activate fish | source
    end

    # --- direnv 项目环境 ---
    if command -q direnv
        direnv hook fish | source
    end

    # --- carapace 通用补全引擎 ---
    # 安装: paru -S carapace-bin
    # 作用: opencode/hermes/cargo/gh/kubectl 等一个补全搞定 zsh/fish/bash
    if command -q carapace
        set -gx CARAPACE_BRIDGES 'zsh,fish,bash,inshellisense'
        carapace _carapace fish | source
    end
end
