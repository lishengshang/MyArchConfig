#!/bin/bash
#
# cava.sh — waybar 音频可视化条 (cava 频谱字符动画)。
#
# 功能: 有未暂停的音频流时驱动 cava 输出频谱; 静默时输出静态条并用
#   pactl subscribe 被动唤醒, 空闲零轮询开销。
# 依赖: cava、pactl (pulseaudio/pipewire-pulse)、sed、flock
# 调用方: modules.jsonc custom/cava (exec 模式, 启动一次常驻读 stdout,
#   无 interval; 每个显示器一个 bar 实例)。
# 并发: flock 单例, 仅一个实例真正启动 cava, 其余实例输出静态条;
#   锁被孤儿/旧实例占住时低频重试接管, 避免模块永久失效。

# 配置
CHARS="▁▂▃▄▅▆▇█"
BARS=10
CONF="${XDG_RUNTIME_DIR:-/tmp}/waybar_cava_config"

# 初始化
len=$((${#CHARS}-1))
idle_char="${CHARS:0:1}"
idle_output=$(printf "%0.s$idle_char" $(seq 1 $BARS))

# 生成 Cava 配置
cat > "$CONF" <<EOF
[general]
bars = $BARS
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = $len
EOF

# 单例锁：waybar 在多个显示器上各起一个 bar 时会执行两次本脚本，
# 用 flock 保证只有一个实例真正启动 cava，其余实例输出静态条。
# fd 200 在脚本退出时自动关闭，锁随之释放，无需手动清理。
exec 200>"${XDG_RUNTIME_DIR:-/tmp}"/cava.sh.lock
if ! flock -n 200; then
    # 锁被占: 可能是双 bar 的另一实例 (正常), 也可能是 waybar 重启
    # (Mod+F2) 留下的孤儿 (它握着锁但可能永不输出, 靠 SIGPIPE 自愈不可靠)。
    # 先输出静态条, 再低频重试接管 ~30s; 孤儿被 binds.kdl 的 pkill 清理后
    # 新实例即可接管, 模块不会永久停在静态条。
    echo "$idle_output"
    for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
        sleep 2
        if flock -n 200; then
            break
        fi
    done
    flock -n 200 || exit 0
fi

cleanup() {
    trap - EXIT INT TERM
    pkill -P $$ 2>/dev/null
    echo "$idle_output"
    exit 0
}
trap cleanup EXIT INT TERM

# 核心检测：是否存在未暂停的音频流
is_audio_active() {
    pactl list sink-inputs 2>/dev/null | grep -q "Corked: no"
}

# 启动 cava 子进程（抽出公用：正常启动与僵尸流重启走同一路径）
start_cava() {
    # 这里的 sed 字典是根据你的 CHARS 动态生成的
    sed_dict="s/;//g;"
    for ((i=0; i<=${len}; i++)); do
        sed_dict="${sed_dict}s/$i/${CHARS:$i:1}/g;"
    done
    cava -p "$CONF" 2>/dev/null | sed -u "$sed_dict" &
}

# cava 的录音流是否仍挂在 PipeWire 上。
# 休眠唤醒/默认设备消失会把 cava 的录音流掐断而进程仍存活（僵尸化，
# 实证见 MAINTENANCE_PLAN P3-23）：此时 cava 持续输出静态数据，
# waybar 表现为频谱条永远不动，必须杀掉进程重启才能重建流。
cava_stream_ok() {
    local pid="$1"
    [ -n "$pid" ] || return 1
    pactl list source-outputs 2>/dev/null | grep -q "application.process.id = \"$pid\""
}

# 初始状态
echo "$idle_output"

# 新建的 cava 注册录音流需要零点几秒，宽限几轮再开始查流，防止误杀
stream_grace=0

while true; do
    # 如果存在未静音的音频
    if is_audio_active; then
        cava_pid="$(pgrep -P $$ -x cava | head -n1)"
        if [ -z "$cava_pid" ]; then
            start_cava
            stream_grace=2
        elif [ "$stream_grace" -gt 0 ]; then
            stream_grace=$((stream_grace-1))
        elif ! cava_stream_ok "$cava_pid"; then
            # 僵尸流：进程在但录音流已断，重启 cava 重建流
            pkill -P $$ -x cava 2>/dev/null
            wait "$cava_pid" 2>/dev/null
            start_cava
            stream_grace=2
        fi
        # 正在播放时，稍微降低检查频率减少 CPU 占用
        sleep 1
    else
        stream_grace=0
        if pgrep -P $$ -x cava >/dev/null; then
            pkill -P $$ -x cava 2>/dev/null
            wait 2>/dev/null
            echo "$idle_output"
        fi
        # 没声音时，使用 subscribe 等待事件，被动唤醒，不产生任何循环开销
        timeout 5s pactl subscribe 2>/dev/null | grep --line-buffered "sink-input" | head -n 1 >/dev/null
    fi
done
