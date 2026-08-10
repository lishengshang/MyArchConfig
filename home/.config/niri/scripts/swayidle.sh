#!/usr/bin/env bash
#
# swayidle 守护进程包装器
#
# 实现：5 分钟锁屏 / 10 分钟熄屏 / 20 分钟休眠
# 任何途径的休眠都会先锁屏（before-sleep 兜底），唤醒后自动点亮屏幕。
#
# 设计要点：
#   - flock 防多实例：niri 重载配置时不会重复拉起第二个 swayidle
#   - set -euo pipefail：严格模式，遇到错误立即退出
#   - exec swayidle：替换 shell 进程，让 systemd / niri 直接监督 swayidle
#                    （信号直达、systemd Restart 生效、stderr 进 journald）
#   - before-sleep / after-resume：覆盖所有休眠/唤醒路径
#   - 每个 timeout 都挂 resume：唤醒流程统一
#
# 推荐启动方式（任选其一）：
#   1) systemd user service（推荐，见 ~/.config/systemd/user/swayidle.service）
#      systemctl --user enable --now swayidle.service
#   2) niri spawn-at-startup（回退方案）
#      spawn-at-startup "~/.config/niri/scripts/swayidle.sh"
#

set -euo pipefail

# ─── 配置 ────────────────────────────────────────────────────────────────────
# 单位：秒。修改这里即可调整时长。
LOCK_TIMEOUT=300        # 5 分钟：锁屏
SCREEN_TIMEOUT=600      # 10 分钟：熄屏
SUSPEND_TIMEOUT=1200    # 20 分钟：休眠

# ─── 日志辅助 ────────────────────────────────────────────────────────────────
log()  { printf '[swayidle] %s\n' "$*" >&2; }
fail() { printf '[swayidle] ERROR: %s\n' "$*" >&2; exit 1; }

# ─── 环境检查 ────────────────────────────────────────────────────────────────
# XDG_RUNTIME_DIR：flock 锁文件路径 + Wayland socket 所在
# WAYLAND_DISPLAY：swayidle 连接 compositor 用
[[ -n "${XDG_RUNTIME_DIR:-}" ]] || fail "XDG_RUNTIME_DIR 未设置，可能不在 Wayland 会话中"
[[ -n "${WAYLAND_DISPLAY:-}" ]] || fail "WAYLAND_DISPLAY 未设置，可能不在 Wayland 会话中"

# 依赖命令存在性检查
for cmd in swayidle swaylock niri systemctl; do
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
#        锁时序正确（确保 swaylock 锁屏后才放行系统休眠）。
#
# swaylock -f：daemonize 模式，锁屏完成后立即返回，让 swayidle 继续处理后续
#              timeout / resume。若不加 -f，swaylock 会阻塞直到解锁，
#              swayidle 的 -w 会一直等下去，后续规则全部失效。
#
# 钩子覆盖矩阵：
#   ┌──────────────┬─────────────────────────────┬────────────────────────────┐
#   │ 触发          │ 执行动作                     │ resume (用户恢复输入)      │
#   ├──────────────┼─────────────────────────────┼────────────────────────────┤
#   │ 5 分钟空闲    │ swaylock -f                  │ power-on-monitors         │
#   │ 10 分钟空闲   │ power-off-monitors           │ power-on-monitors         │
#   │ 20 分钟空闲    │ systemctl suspend           │ power-on-monitors         │
#   │ 任意休眠      │ swaylock -f (before-sleep)   │ power-on-monitors         │
#   │                │                              │   (after-resume)          │
#   └──────────────┴─────────────────────────────┴────────────────────────────┘

exec swayidle -w \
    timeout "$LOCK_TIMEOUT"     'swaylock -f' \
        resume                   'niri msg action power-on-monitors' \
    timeout "$SCREEN_TIMEOUT"   'niri msg action power-off-monitors' \
        resume                   'niri msg action power-on-monitors' \
    timeout "$SUSPEND_TIMEOUT"  'systemctl suspend' \
        resume                   'niri msg action power-on-monitors' \
    before-sleep                'swaylock -f' \
    after-resume                'niri msg action power-on-monitors'
