#!/bin/bash
# 监听 systemd-logind 的 PrepareForSleep 信号，在每次唤醒后延迟重启
# WirePlumber，修复 suspend-then-hibernate 唤醒后音频设备全部消失的问题。
#
# 实证（2026-09-14）：s2idle→休眠切换瞬间 WirePlumber 的 alsa.lua 崩溃后
# 进入坏状态——内置声卡 profile 卡在 off、蓝牙耳机不建节点，所有声音进
# auto_null 虚拟输出；手动 `systemctl --user restart wireplumber` 即恢复。
# 完整分析见 MAINTENANCE_PLAN.md P3-20。
#
# 解析说明：系统总线上非 root 的 dbus-monitor 无法启用 new-style 监听，
# 会回退 eavesdropping 模式（匹配规则失效、所有信号都打印）。因此不能
# 只匹配 "boolean false" 字符串（PropertiesChanged 里的 variant boolean
# false 会误触发），必须用状态机：先见到 member=PrepareForSleep，紧随
# 其后的 boolean false 才算唤醒事件。
#
# 测试钩子：GUARD_TEST=1 时不真正重启只打标记；GUARD_TEST_SRC=<file>
# 时改从文件读入样例输出，用于离线验证解析逻辑（见 MAINTENANCE_PLAN
# P3-20 的验证记录）。

set -u

restart_action() {
    # 延迟 5 秒：给 ALSA/蓝牙设备重新枚举留时间，避免在设备未就绪时重建节点
    sleep 5
    # 只重启 WirePlumber（设备管家），不动 PipeWire 本体；客户端音频流
    # 自动重连，代价是唤醒后约半秒的音频短暂中断
    systemctl --user restart wireplumber.service
}

if [ "${GUARD_TEST:-0}" = 1 ]; then
    restart_action() { echo "TEST: restart wireplumber (triggered)"; }
fi

process_events() {
    local expect=false line
    while read -r line; do
        case "$line" in
            *member=PrepareForSleep*)
                expect=true
                ;;
            *boolean*)
                [ "$expect" = true ] || continue
                expect=false
                case "$line" in
                    *boolean\ false*) restart_action ;;
                esac
                ;;
        esac
    done
}

if [ -n "${GUARD_TEST_SRC:-}" ]; then
    process_events < "$GUARD_TEST_SRC"
else
    dbus-monitor --system \
        "type='signal',interface='org.freedesktop.login1.Manager',member='PrepareForSleep'" |
        process_events
fi

# 走到这里说明流结束（dbus-monitor 断开/挂掉）。以非零退出交给
# systemd 的 Restart=on-failure 拉起，避免静默失去监听。
exit 1
