#!/usr/bin/env bash

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

    # 2. 监听事件流，等待截图完成（timeout 10 防止按 Esc 取消后永久挂住）
    log_output=$(timeout 10 niri msg event-stream | grep -m 1 --line-buffered "Screenshot captured")

    # 3. 从事件中提取出图片文件路径
    file_path="${log_output##*saved to }"

    # 4. 检查路径是否非空（防止按 Esc 取消截图导致没有路径）
    if [ -n "$file_path" ]; then
        # 把图片传给 Satty 进行编辑
        satty --filename "$file_path"
    fi
else
    # [旧版本回退逻辑] 基于剪贴板检测
    # 记录初始剪贴板哈希并启动截图
    CLIP_BASE=$(wl-paste | sha1sum)
    niri msg action screenshot

    # 轮询等待剪贴板内容变化
    while [ "$(wl-paste | sha1sum)" = "$CLIP_BASE" ]; do
        sleep 0.2
    done

    # 将新的剪贴板内容传给 Satty
    wl-paste | satty -f -
fi