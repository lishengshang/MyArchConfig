#!/bin/bash
# 监听 PipeWire 音量变化并弹出 swayosd 浮窗，补上不经 swayosd-client 的调节路径。
#
# 背景：耳机机身上的音量键走蓝牙 AVRCP 绝对音量协议，由耳机固件直接改
# sink 音量（步长约 5~6%，固件决定，软件侧无法调细），整个过程不经过
# swayosd-client，因此系统侧没有任何浮窗反馈。本守护进程让"任何来源"
# 的默认输出音量变化都弹出浮窗显示当前音量。
#
# 设计：
#   - 启动时先读一次当前音量作为基准，避免服务刚起时被无关的 sink
#     状态变化（如开始播放触发 IDLE→RUNNING）误弹一次；
#   - pactl subscribe 阻塞监听，只处理 sink 本体的 change 事件
#     （"on sink #N"，排除 sink-input 应用流，避免播放期间频繁唤醒）；
#   - 音量值去重，同一数值不重复弹；
#   - 触发用 swayosd-client --output-volume +0：相对 +0 是空操作，
#     只显示当前音量，不存在"读到旧值再写回、吃掉用户按键"的竞态；
#   - pactl 断开（如 pipewire-pulse 重启）时以非零退出，由 systemd
#     Restart=on-failure 拉起。

set -u

read_vol() {
    local cur
    cur="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)" || return 1
    # 形如 "Volume: 0.63" 或 "Volume: 0.63 [MUTED]"
    cur="${cur#Volume: }"
    printf '%s' "${cur%%[[:space:]]*}"
}

last_vol="$(read_vol || printf '')"

pactl subscribe 2>/dev/null | while read -r event; do
    case "$event" in
        *"'change' on sink #"*) ;;
        *) continue ;;
    esac

    # 轻防抖：等一拍让连续事件（AVRCP 同步常连发多条）落定
    sleep 0.2

    cur="$(read_vol)" || continue
    [ "$cur" = "$last_vol" ] && continue
    last_vol="$cur"

    swayosd-client --output-volume +0 >/dev/null 2>&1
done

# 流结束视为异常，非零退出交给 systemd 重启
exit 1
