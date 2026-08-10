# =============================================================================
# ~/.zshenv — zsh 的入口点（所有 zsh 实例都会读）
# =============================================================================
# 此文件只做一件事：把 ZDOTDIR 指向 XDG 配置目录，然后 source 真正的配置。
#
# 当 systemd 已通过 environment.d 设置 ZDOTDIR 时，zsh 直接读
# $ZDOTDIR/.zshenv，跳过此文件 → 不会重复 source。
#
# 当 ZDOTDIR 未在环境中（SSH、恢复模式等），zsh 读此文件 →
# 设置 ZDOTDIR + 手动 source $ZDOTDIR/.zshenv。
# =============================================================================

export ZDOTDIR="$HOME/.config/zsh"

# 非 systemd 环境下手动 source 真正的 .zshenv
# systemd 环境下此文件不会被读取，不会重复
if [[ -r "$ZDOTDIR/.zshenv" ]]; then
    source "$ZDOTDIR/.zshenv"
fi
