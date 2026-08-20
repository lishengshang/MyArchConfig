#!/usr/bin/env bash
#
# swayidle 守护进程包装器
#
# 实现：8 分钟锁屏 / 15 分钟熄屏 / 25 分钟休眠
# 任何途径的休眠都会先锁屏（before-sleep 兜底），唤醒后自动点亮屏幕。
#
# 设计要点：
#   - flock 防多实例：niri 重载配置时不会重复拉起第二个 swayidle
#   - set -euo pipefail：严格模式，遇到错误立即退出
#   - exec swayidle：替换 shell 进程，让 systemd / niri 直接监督 swayidle
#                    （信号直达、systemd Restart 生效、stderr 进 journald）
#   - before-sleep / after-resume：覆盖所有休眠/唤醒路径
#   - 每个 timeout 都挂 resume：唤醒流程统一
#   - 锁屏统一走 scripts/lock-screen.sh（hyprlock）：
#       * 手动/自动锁屏同一个 hyprlock，不再使用 swaylock
#       * pgrep 防双实例：已锁定则跳过（niri 也只允许一个锁屏客户端）
#       * 熄屏前兜底锁屏：修复"解锁后长时间空闲，屏幕熄了但没锁定"的问题
#
# 推荐启动方式（任选其一）：
#   1) systemd user service（推荐，见 ~/.config/systemd/user/swayidle.service）
#      systemctl --user start swayidle.service
#   2) niri spawn-at-startup（回退方案）
#      spawn-at-startup "~/.config/niri/scripts/swayidle.sh"
#

set -euo pipefail

# swayidle/hyprlock 只属于 Niri。即使 unit 被误启动，也不能在 KDE
# 中参与锁屏、suspend 或 NVIDIA 的 sleep 流程。
if ! pgrep -u "${UID:-$(id -u)}" -x niri >/dev/null 2>&1; then
    exit 0
fi

# ─── 配置 ────────────────────────────────────────────────────────────────────
# 单位：秒。修改这里即可调整时长。
LOCK_TIMEOUT=480        # 8 分钟：锁屏
SCREEN_TIMEOUT=600      # 10 分钟：熄屏（锁屏后 2 分钟，未锁定则先锁屏）
SUSPEND_TIMEOUT=1200    # 20 分钟：挂起（挂起满 1.5 小时后自动转休眠）

# 统一锁屏入口。
# 所有 timeout 和 before-sleep 都使用 --wait-ready，确认 hyprlock 已建立后
# 再继续，避免锁屏失败后继续熄屏或 suspend。
# 注意：swayidle 用 sh -c 执行命令字符串，这里的 $HOME 会在运行时由 sh 展开。
LOCK_CMD='$HOME/.config/niri/scripts/lock-screen.sh --wait-ready'
LOCK_READY_CMD='$HOME/.config/niri/scripts/lock-screen.sh --wait-ready'

# ─── 日志辅助 ────────────────────────────────────────────────────────────────
log()  { printf '[swayidle] %s\n' "$*" >&2; }
fail() { printf '[swayidle] ERROR: %s\n' "$*" >&2; exit 1; }

# ─── 环境检查 ────────────────────────────────────────────────────────────────
# XDG_RUNTIME_DIR：flock 锁文件路径 + Wayland socket 所在
# WAYLAND_DISPLAY：swayidle 连接 compositor 用
[[ -n "${XDG_RUNTIME_DIR:-}" ]] || fail "XDG_RUNTIME_DIR 未设置，可能不在 Wayland 会话中"
[[ -n "${WAYLAND_DISPLAY:-}" ]] || fail "WAYLAND_DISPLAY 未设置，可能不在 Wayland 会话中"

# 依赖命令存在性检查
for cmd in swayidle hyprlock niri systemctl; do
    command -v "$cmd" >/dev/null 2>&1 || fail "缺少依赖命令: $cmd"
done

# ─── 防多实例 (flock) ────────────────────────────────────────────────────────
# 锁文件放在 $XDG_RUNTIME_DIR（tmpfs，按用户隔离，会话结束自动清理）。
# flock 在进程退出（包括 SIGKILL）时由内核自动释放，不会留死锁。
# -n: 非阻塞，抢不到锁立即返回失败。
LOCK_FILE="$XDG_RUNTIME_DIR/swayidle.lock"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    log "已有实例在运行（锁文件：$LOCK_FILE），本次启动退出"
    exit 0
fi

# ─── 启动 swayidle ────────────────────────────────────────────────────────────
# 关键参数：
#   -w   wait 模式，等待 Wayland 连接建立；且让 before-sleep 的 inhibition
#        锁时序正确（确保锁屏后才放行系统休眠）。
#
# 钩子覆盖矩阵：
#   ┌──────────────┬──────────────────────────────────┬────────────────────────────┐
#   │ 触发          │ 执行动作                          │ resume (用户恢复输入)      │
#   ├──────────────┼──────────────────────────────────┼────────────────────────────┤
#   │ 8 分钟空闲    │ lock-screen.sh（hyprlock 锁屏）    │ power-on-monitors         │
#   │ 15 分钟空闲   │ lock-screen.sh 兜底 + 熄屏         │ power-on-monitors         │
#   │ 20 分钟空闲   │ 亮屏+suspend-then-hibernate        │ power-on-monitors         │
#   │ 任意休眠      │ lock-screen.sh（before-sleep 兜底）│ power-on-monitors         │
#   │                │                                  │   (after-resume)          │
#   └──────────────┴──────────────────────────────────┴────────────────────────────┘
#   说明：15 分钟熄屏时若 8 分钟锁屏仍生效（正常路径），lock-screen.sh 会因
#   pgrep 已检测到 hyprlock 而直接跳过，不会叠加锁屏实例。

exec swayidle -w \
    timeout "$LOCK_TIMEOUT"     "$LOCK_CMD" \
        resume                   'niri msg action power-on-monitors' \
    timeout "$SCREEN_TIMEOUT"   "$LOCK_READY_CMD && niri msg action power-off-monitors" \
        resume                   'niri msg action power-on-monitors' \
    timeout "$SUSPEND_TIMEOUT"  'niri msg action power-on-monitors && systemctl suspend-then-hibernate' \
        resume                   'niri msg action power-on-monitors' \
    before-sleep                "$LOCK_READY_CMD" \
    after-resume                'niri msg action power-on-monitors'
