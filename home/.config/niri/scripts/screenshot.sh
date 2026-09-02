#!/usr/bin/env bash
#
# screenshot.sh — niri 区域截图并用 satty 标注编辑（Mod+P 等快捷键调用）
#
# 依赖: niri (msg action/event-stream)、satty；旧版本分支另需 wl-paste (wl-clipboard)
# 用法: screenshot.sh   (无参数)
#
# 按 niri 版本分流：
#   >= 25.08: 走事件流，从 "Screenshot captured ... saved to <path>" 提取保存路径
#   <  25.08: 回退到剪贴板哈希变化检测（老版本无截图事件）
# 注意: 截图选区是交互式的，用户拖选可能超过半分钟，等待超时必须远大于
#   正常选图时间；超时仅作为"按 Esc 取消/事件丢失"时的防挂死兜底。

set -u

# 等待用户完成选区的上限（秒）。这只是防挂死兜底，正常流程在
# "Screenshot captured" 事件到达时立即继续，不受此值限制。
WAIT_TIMEOUT=60

# 设定触发新逻辑的目标版本号
TARGET_VERSION="25.08"

# 获取当前 niri 版本（兼容 "niri 26.04 (xxx)" / "v26.04" / "26.04.1" 等格式）
CURRENT_VERSION=$(niri -V 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)

# 兜底：提取失败则走旧版本分支
[[ -z "$CURRENT_VERSION" ]] && CURRENT_VERSION="0"

# 版本比较：$1 >= $2 返回 0（true）
version_ge() {
    [[ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" = "$2" ]]
}

# 根据版本不同执行不同逻辑
if version_ge "$CURRENT_VERSION" "$TARGET_VERSION"; then
    # [新版本逻辑] 基于事件流，更精准
    # 1. 后台启动截图，不阻塞脚本
    niri msg action screenshot &

    # 2. 监听事件流，等待截图完成（timeout 仅作防挂死兜底，见文件头注释）
    log_output=$(timeout "$WAIT_TIMEOUT" niri msg event-stream | grep -m 1 --line-buffered "Screenshot captured")

    # 3. 从事件中提取出图片文件路径
    file_path="${log_output##*saved to }"

    # 4. 校验：事件缺失/超时/按 Esc 取消时，提取结果不会指向真实文件
    if [ -n "$file_path" ] && [ "$file_path" != "$log_output" ] && [ -f "$file_path" ]; then
        # 把图片传给 Satty 进行编辑
        satty --filename "$file_path"
    fi
else
    # [旧版本回退逻辑] 基于剪贴板检测（niri < 25.08）
    # 记录初始剪贴板哈希并启动截图
    CLIP_BASE=$(wl-paste 2>/dev/null | sha1sum)
    niri msg action screenshot

    # 轮询等待剪贴板内容变化；同样用 WAIT_TIMEOUT 防挂死（用户按 Esc
    # 取消时剪贴板永远不变，不能无限轮询留下孤儿进程）
    ELAPSED=0
    while [ "$(wl-paste 2>/dev/null | sha1sum)" = "$CLIP_BASE" ]; do
        sleep 0.2
        ELAPSED=$((ELAPSED + 1))
        [ "$ELAPSED" -ge $((WAIT_TIMEOUT * 5)) ] && exit 0
    done

    # 将新的剪贴板内容传给 Satty
    wl-paste | satty -f -
fi
