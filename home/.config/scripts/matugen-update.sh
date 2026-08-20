#!/bin/bash

# --- 1. 参数解析 ---
WALLPAPER=""
NO_INDEX=false
FORCE_UPDATE=false # 【新增】：强制更新标志

show_help() {
    echo "Usage: matugen-update.sh [OPTIONS] [WALLPAPER]"
    echo ""
    echo "Options:"
    echo "  -h, --help       显示此帮助信息"
    echo "  -n, --no-index   不指定 index，在终端运行时唤起 matugen 原生的交互式颜色选择"
    echo "  -f, --force      强制重新生成，忽略壁纸未更改的检查" # 【新增】
    exit 0
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -n|--no-index)
            NO_INDEX=true
            shift
            ;;
        -f|--force)          # 【新增】：捕获强制更新参数
            FORCE_UPDATE=true
            shift
            ;;
        *)
            WALLPAPER="$1"
            shift
            ;;
    esac
done

# --- 2. 路径与状态定义 ---
CACHE_DIR="$HOME/.cache/matugen-strategy"
TYPE_FILE="$CACHE_DIR/type"
MODE_FILE="$CACHE_DIR/mode"
INDEX_MODE_FILE="$CACHE_DIR/index_mode"
LAST_WALL_FILE="$CACHE_DIR/last_wallpaper"     
CURRENT_INDEX_FILE="$CACHE_DIR/current_index"  
VALID_INDICES_FILE="$CACHE_DIR/valid_indices"  
SHRUNK_CACHE_DIR="$CACHE_DIR/shrunk_images"   

# 新增：用于记录上次生成壁纸路径以跳过重复任务的目录和文件
UPDATE_CACHE_DIR="$HOME/.cache/matugen-update"
mkdir -p "$UPDATE_CACHE_DIR"
LAST_PROCESSED_WALL_FILE="$UPDATE_CACHE_DIR/last_wallpaper_path"

# 单实例锁：timer/waybar/手动调用可能并发，防止竞态写缓存（空缓存曾导致崩溃）。
# 用 mkdir+PID 自愈锁而非 flock: flock 的 fd 可能被外部进程继承(实测 swayosd-server
# 曾因此永久占用锁, 导致所有后续更新被跳过); PID 锁在持有者崩溃/被杀后可自动接管。
LOCK_DIR="$UPDATE_CACHE_DIR/update.lock"
if ! mkdir "$LOCK_DIR" 2>/dev/null; then
    LOCK_PID=$(cat "$LOCK_DIR/pid" 2>/dev/null)
    if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
        echo "matugen-update 已有实例在运行，退出" >&2
        exit 0
    fi
    # 持有者已死: 清理残留锁并接管 (旧的 flock 文件残留也会在此被替换)
    rm -rf "$LOCK_DIR" 2>/dev/null
    mkdir "$LOCK_DIR" 2>/dev/null || { echo "matugen-update 锁竞争，退出" >&2; exit 0; }
fi
echo "$$" > "$LOCK_DIR/pid"
trap 'rm -rf "$LOCK_DIR"' EXIT

WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

mkdir -p "$SHRUNK_CACHE_DIR"

# --- 3. 获取当前聚焦显示器的壁纸路径 ---
if [ -z "$WALLPAPER" ]; then
    # 使用 niri 获取当前聚焦的显示器，并使用 awww 获取对应的壁纸
    if command -v niri &>/dev/null && command -v awww &>/dev/null; then
        # 提取括号内的显示器名称，例如：Output "..." (DP-2) -> DP-2
        FOCUSED_OUTPUT=$(niri msg focused-output | head -n 1 | awk -F '[()]' '{print $2}')
        
        if [ -n "$FOCUSED_OUTPUT" ]; then
            # 匹配显示器并提取 image: 后面的路径（同时去除首尾可能存在的多余空格）
            DETECTED_WALL=$(awww query | grep "^: ${FOCUSED_OUTPUT}:" | awk -F 'image: ' '{print $2}' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            if [ -n "$DETECTED_WALL" ] && [ -f "$DETECTED_WALL" ]; then
                WALLPAPER="$DETECTED_WALL"
            fi
        fi
    fi
    
    # Fallback 降级方案：读取 waypaper 配置文件
    if [ -z "$WALLPAPER" ] && [ -f "$WAYPAPER_CONFIG" ]; then
        WP_PATH=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG")
        WP_PATH="${WP_PATH/#\~/$HOME}"
        if [ -n "$WP_PATH" ] && [ -f "$WP_PATH" ]; then
            WALLPAPER="$WP_PATH"
        elif [ -n "$WP_PATH" ]; then
            # wallpaper 字段指向的文件已不存在 (可能被清理), 取 folder 里最新的一张图兜底
            WP_FOLDER=$(sed -n 's/^folder[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG")
            WP_FOLDER="${WP_FOLDER/#\~/$HOME}"
            if [ -d "$WP_FOLDER" ]; then
                FALLBACK_IMG=$(find "$WP_FOLDER" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%T@\t%p\n' 2>/dev/null | sort -rn | head -n1 | cut -f2-)
                if [ -n "$FALLBACK_IMG" ] && [ -f "$FALLBACK_IMG" ]; then
                    WALLPAPER="$FALLBACK_IMG"
                fi
            fi
        fi
    fi
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    notify-send "Matugen Error" "无法找到壁纸路径。"
    exit 1
fi
ln -sf "$WALLPAPER" "$HOME/.cache/.current_wallpaper"


# --- 4. 读取策略与模式，并判断是否需要跳过重复生成 ---
# 手动编辑状态文件可能带尾随空格/换行, 读取时统一 trim, 避免 matugen 参数错误
trim() { sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }
if [ -f "$TYPE_FILE" ]; then STRATEGY=$(trim < "$TYPE_FILE"); else STRATEGY="scheme-tonal-spot"; fi
if [ -f "$MODE_FILE" ]; then MODE=$(trim < "$MODE_FILE"); else MODE="dark"; fi

FORCE_ZERO=true
if [ -f "$INDEX_MODE_FILE" ]; then
    if [ "$(trim < "$INDEX_MODE_FILE")" == "random" ]; then
        FORCE_ZERO=false
    fi
fi

#[新增逻辑]：检测下一次传入的壁纸路径是否和上一次相同
if [ -f "$LAST_PROCESSED_WALL_FILE" ]; then
    LAST_PROCESSED_WALL=$(cat "$LAST_PROCESSED_WALL_FILE")
else
    LAST_PROCESSED_WALL=""
fi

# 【修改】：加入了 FORCE_UPDATE=false 的判断。如果传入了 -f 参数，将无视壁纸是否相同，强制生成
if [ "$FORCE_UPDATE" = false ] && [ "$WALLPAPER" == "$LAST_PROCESSED_WALL" ] && [ "$FORCE_ZERO" = true ] && [ "$NO_INDEX" = false ]; then
    echo "Wallpaper unchanged for the focused monitor. Skipping Matugen update."
    exit 0
fi


# --- 5. [智能缓存] 哈希化与选择性转换 ---
# 利用 MD5 生成该路径独一无二的缓存文件名
WALL_HASH=$(echo -n "$WALLPAPER" | md5sum | awk '{print $1}')
CACHED_IMAGE="$SHRUNK_CACHE_DIR/${WALL_HASH}.png"
TARGET_IMAGE="$WALLPAPER" # 默认直接喂原图

# 仅获取真实 MIME 类型
FILE_MIME=$(file -b --mime-type "$WALLPAPER")
NEED_CONVERT=false

# 只有真实格式是 webp 时，才触发 ImageMagick 转换
if [[ "$FILE_MIME" == *"webp"* ]]; then
    NEED_CONVERT=true
fi

if [ "$NEED_CONVERT" = true ]; then
    TARGET_IMAGE="$CACHED_IMAGE"
    # 缓存不存在或已损坏(如旧版脚本失败时留下的错误文本)时重新转换
    CACHE_VALID=false
    if [ -f "$CACHED_IMAGE" ]; then
        CACHE_MIME=$(file -b --mime-type "$CACHED_IMAGE" 2>/dev/null)
        [[ "$CACHE_MIME" == image/* ]] && CACHE_VALID=true
    fi
    if [ "$CACHE_VALID" = false ]; then
        # '500x500>' 必须整体加引号: 否则 shell 把 > 当重定向, 500x500 被当成输入文件, 命令必失败
        if command -v magick &>/dev/null; then
            CONVERT_CMD=(magick "$WALLPAPER" -resize '500x500>' "$CACHED_IMAGE")
        elif command -v convert &>/dev/null; then
            CONVERT_CMD=(convert "$WALLPAPER" -resize '500x500>' "$CACHED_IMAGE")
        elif command -v ffmpeg &>/dev/null; then
            CONVERT_CMD=(ffmpeg -y -i "$WALLPAPER" -vf "scale='min(500,iw)':-1" "$CACHED_IMAGE")
        else
            # 没有工具就只能硬着头皮上原图了
            TARGET_IMAGE="$WALLPAPER"
        fi
        if [ -n "${CONVERT_CMD+x}" ]; then
            if ! "${CONVERT_CMD[@]}" 2>/dev/null; then
                # 转换失败必须删坏缓存并中止, 否则下次 [ ! -f 缓存 ] 为假, 永远跳过转换
                rm -f "$CACHED_IMAGE"
                notify-send "Matugen Error" "图片转换失败，无法生成缓存: $(basename "$WALLPAPER")"
                exit 1
            fi
        fi
    fi
fi

# 检查是否换了壁纸，用于清空有效颜色的探测状态
LAST_WALL=""
[ -f "$LAST_WALL_FILE" ] && LAST_WALL=$(cat "$LAST_WALL_FILE")
if [ "$LAST_WALL" != "$WALLPAPER" ]; then
    rm -f "$VALID_INDICES_FILE"
fi

# --- 6. 执行 Matugen ---
# 探测当前图片可用的 source-color-index 列表并写入缓存。
# 探测全部失败（如非终端环境无偏好输入）时兜底 index 0，
# 且保证缓存文件写入的是非空列表，避免下次"光速轮换"读到空数组。
probe_valid_indices() {
    VALID_INDICES=()
    # 探测全部 0..5, 不因某个 index 无效就 break, 避免漏掉后续仍然有效的 index
    for i in {0..5}; do
        if matugen image "$TARGET_IMAGE" --source-color-index "$i" --dry-run &>/dev/null; then
            VALID_INDICES+=("$i")
        fi
    done
    if [ ${#VALID_INDICES[@]} -eq 0 ]; then
        VALID_INDICES=(0)
    fi
    printf '%s\n' "${VALID_INDICES[*]}" > "$VALID_INDICES_FILE"
}

if [ "$NO_INDEX" = true ]; then
    # 交互模式 (由终端唤起, 用户手动选色)
    if matugen image "$TARGET_IMAGE" -t "$STRATEGY" -m "$MODE"; then
        echo "$WALLPAPER" > "$LAST_WALL_FILE"
    else
        # 生成失败 (含 Ctrl-C 中断): 不更新任何状态, 避免下次误判已处理
        notify-send "Matugen Error" "matugen 生成失败，状态未更新"
        exit 1
    fi
else
    # 后台自动化模式
    SELECTED_INDEX=""
    if [ "$FORCE_ZERO" = true ]; then
        SELECTED_INDEX=0
    elif [ "$LAST_WALL" == "$WALLPAPER" ] && [ -f "$VALID_INDICES_FILE" ] && [ -f "$CURRENT_INDEX_FILE" ]; then
        # 光速轮换：缓存齐全时直接轮换，不重复探测
        read -r -a VALID_INDICES < "$VALID_INDICES_FILE" || VALID_INDICES=()
        LAST_INDEX=$(cat "$CURRENT_INDEX_FILE")
        NEXT_POS=0
        if [ ${#VALID_INDICES[@]} -gt 0 ]; then
            for j in "${!VALID_INDICES[@]}"; do
                if [ "${VALID_INDICES[$j]}" == "$LAST_INDEX" ]; then
                    NEXT_POS=$(( (j + 1) % ${#VALID_INDICES[@]} ))
                    break
                fi
            done
            SELECTED_INDEX=${VALID_INDICES[$NEXT_POS]}
        fi
        # 空/异常缓存守卫：读不到有效 index 时重新探测，避免传空值给 matugen
        if [ -z "$SELECTED_INDEX" ]; then
            probe_valid_indices
            RANDOM_INDEX=$((RANDOM % ${#VALID_INDICES[@]}))
            SELECTED_INDEX=${VALID_INDICES[$RANDOM_INDEX]}
        fi
    else
        # 首次处理本壁纸：执行探测
        probe_valid_indices
        RANDOM_INDEX=$((RANDOM % ${#VALID_INDICES[@]}))
        SELECTED_INDEX=${VALID_INDICES[$RANDOM_INDEX]}
    fi
    
    # 双保险：任何路径都不允许把空 index 传给 matugen
    SELECTED_INDEX="${SELECTED_INDEX:-0}"
    
    # 最终执行，传入决定好的 TARGET_IMAGE (可能是原图，也可能是缓存的缩小图)
    if matugen image "$TARGET_IMAGE" -t "$STRATEGY" -m "$MODE" --source-color-index "$SELECTED_INDEX"; then
        # 状态持久化: 仅在成功时写入, 失败则下次仍会重新生成
        echo "$SELECTED_INDEX" > "$CURRENT_INDEX_FILE"
        echo "$WALLPAPER" > "$LAST_WALL_FILE"
    else
        notify-send "Matugen Error" "matugen 生成失败，状态未更新"
        exit 1
    fi
fi

# [新增]：将本次成功生成的壁纸路径持久化到要求2的目录中
echo "$WALLPAPER" > "$LAST_PROCESSED_WALL_FILE"

# --- 7. Fcitx5 双模式主题 ---
# 单独用最小 Matugen 配置生成 light/dark 两份 Fcitx5 主题，避免为了
# 输入法重复生成 Waybar 等其他目标。Fcitx5 根据当前桌面的明暗设置选择。
FCITX5_UPDATE="$HOME/.config/matugen/scripts/matugen-fcitx5.sh"
if [[ -x "$FCITX5_UPDATE" ]]; then
    "$FCITX5_UPDATE" "$WALLPAPER" "${SELECTED_INDEX:-0}" "$STRATEGY"
    fcitx5-remote -r >/dev/null 2>&1 || true
fi

# --- 8. GTK 外观由 gtk-theme-by-time.timer 管理 ---
# Matugen 只负责生成 GTK CSS 颜色，不在每次换壁纸时覆盖 GTK 的主题/深浅色。
# 这样 Niri 的定时主题和 KDE 自己的 GTK 主题策略不会被壁纸更新打断。
