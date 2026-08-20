#!/bin/bash

# ==============================================================================
# 1. 用户配置 (User Configuration)
# ==============================================================================

# --- 核心设置 ---
# 可选: "awww" 或 "swaybg"
WALLPAPER_BACKEND="awww" 

# [AWWW 专用] 参数
AWWW_ARGS=(-n overview --transition-type fade --transition-duration 0.5)

# [Swaybg 专用] 填充模式 (fill, fit, center, tile)
SWAYBG_MODE="fill"

# [Waypaper] 配置文件路径 (用于当 backend 为 swaybg 时获取当前壁纸)
WAYPAPER_CONFIG="$HOME/.config/waypaper/config.ini"

# --- ImageMagick 参数 ---
IMG_BLUR_STRENGTH="0x15"
IMG_FILL_COLOR="black"
IMG_COLORIZE_STRENGTH="40%"

# --- 路径配置 ---
REAL_CACHE_BASE="$HOME/.cache/blur-wallpapers"
CACHE_SUBDIR_NAME="niri-overview-blur-dark"
LINK_NAME="cache-niri-overview-blur-dark"

# --- 自动预生成与清理配置 ---
# Do not launch ImageMagick for every wallpaper in WALL_DIR on each switch.
# That background sweep competes with the compositor and causes visible stalls.
AUTO_PREGEN="false"              # true/false：是否在后台进行维护
ORPHAN_CACHE_LIMIT=10            # 允许保留多少个“非重要壁纸”的缓存

# [关键配置] 重要壁纸目录
WALL_DIR="$HOME/Pictures/Wallpapers"


# ==============================================================================
# 1.5 桌面环境检测 (Desktop Environment Check)
# ==============================================================================
# 检测当前是否处于 Niri 环境中。
# 通过忽略大小写的 XDG_CURRENT_DESKTOP 或 Niri 专属的 NIRI_SOCKET 变量进行判断。
if [[ "${XDG_CURRENT_DESKTOP,,}" != "niri" ]] && [[ -z "$NIRI_SOCKET" ]]; then
    echo "当前桌面环境不是 Niri，脚本终止执行。"
    exit 0
fi


# ==============================================================================
# 2. 依赖与输入检查
# ==============================================================================

DEPENDENCIES=("magick" "notify-send")

if [ "$WALLPAPER_BACKEND" == "awww" ]; then
    DEPENDENCIES+=("awww" "niri")
elif [ "$WALLPAPER_BACKEND" == "swaybg" ]; then
    DEPENDENCIES+=("swaybg")
fi

for cmd in "${DEPENDENCIES[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        notify-send -u critical "Blur Error" "缺少依赖: $cmd，请检查是否安装"
        exit 1
    fi
done

# === 多显示器壁纸解析逻辑 ===
declare -A MONITOR_WALLPAPERS

if [ -z "$1" ]; then
    # 策略 1: 尝试从 awww query 获取多屏信息
    if command -v awww &> /dev/null && awww query &> /dev/null; then
        while read -r line; do
            # 匹配包含 image: 的行，提取显示器名和壁纸路径
            if echo "$line" | grep -q "image:"; then
                monitor=$(echo "$line" | cut -d':' -f2 | tr -d ' ')
                img=$(echo "$line" | sed 's/.*image: //')
                if [[ -n "$monitor" && -n "$img" ]]; then
                    MONITOR_WALLPAPERS["$monitor"]="$img"
                fi
            fi
        done < <(awww query 2>/dev/null)
    fi

    # 策略 2: 如果上述没拿到(或未使用 awww)，尝试读取 waypaper 配置
    if [ ${#MONITOR_WALLPAPERS[@]} -eq 0 ] && [ -f "$WAYPAPER_CONFIG" ]; then
        tmp_img=$(sed -n 's/^wallpaper[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG" | head -n1 | xargs)
        tmp_img="${tmp_img/#\~/$HOME}"
        if [ -n "$tmp_img" ] && [ ! -f "$tmp_img" ]; then
            # wallpaper 字段指向的文件已不存在, 取 folder 里最新的一张图兜底
            tmp_folder=$(sed -n 's/^folder[[:space:]]*=[[:space:]]*//p' "$WAYPAPER_CONFIG" | head -n1 | xargs)
            tmp_folder="${tmp_folder/#\~/$HOME}"
            if [ -d "$tmp_folder" ]; then
                tmp_img=$(find "$tmp_folder" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \) -printf '%T@\t%p\n' 2>/dev/null | sort -rn | head -n1 | cut -f2-)
            fi
        fi
        if [ -n "$tmp_img" ]; then
            MONITOR_WALLPAPERS["all"]="$tmp_img"
        fi
    fi
else
    # 策略 3: 用户手动指定参数，应用于所有显示器
    MONITOR_WALLPAPERS["all"]="$1"
fi

if [ ${#MONITOR_WALLPAPERS[@]} -eq 0 ]; then
    notify-send "Blur Error" "无法自动获取当前壁纸。请手动指定路径。"
    exit 1
fi

# 获取任意一个可用壁纸以推导目录
FIRST_IMG=""
for m in "${!MONITOR_WALLPAPERS[@]}"; do
    FIRST_IMG="${MONITOR_WALLPAPERS[$m]}"
    break
done

# 如果配置的 WALL_DIR 不存在，回退到当前图片所在目录
if [ -z "$WALL_DIR" ] || [ ! -d "$WALL_DIR" ]; then
    WALL_DIR=$(dirname "$FIRST_IMG")
fi

# ==============================================================================
# 3. 路径链接与壁纸处理逻辑
# ==============================================================================

REAL_CACHE_DIR="$REAL_CACHE_BASE/$CACHE_SUBDIR_NAME"
mkdir -p "$REAL_CACHE_DIR"

SYMLINK_PATH="$WALL_DIR/$LINK_NAME"

# 仅当路径不存在或已是符号链接时才重建; 若用户手动放了真实目录则不动它
if [ ! -d "$SYMLINK_PATH" ] || [ -L "$SYMLINK_PATH" ]; then
    ln -sfn "$REAL_CACHE_DIR" "$SYMLINK_PATH"
fi

SAFE_OPACITY="${IMG_COLORIZE_STRENGTH%\%}"
SAFE_COLOR="${IMG_FILL_COLOR#\#}"
PARAM_PREFIX="blur-${IMG_BLUR_STRENGTH}-${SAFE_COLOR}-${SAFE_OPACITY}-"

# 记录当前所有的缓存文件结果
declare -A CACHE_PATHS
declare -A ACTIVE_CACHE_FILES

for monitor in "${!MONITOR_WALLPAPERS[@]}"; do
    img_path="${MONITOR_WALLPAPERS[$monitor]}"
    
    if [ ! -f "$img_path" ]; then
        continue
    fi
    
    FILENAME=$(basename "$img_path")
    BLUR_FILENAME="${PARAM_PREFIX}${FILENAME}.jpg"
    FINAL_IMG_PATH="$REAL_CACHE_DIR/$BLUR_FILENAME"
    
    # 将此文件加入记录，用于后续应用和豁免清理
    CACHE_PATHS["$monitor"]="$FINAL_IMG_PATH"
    ACTIVE_CACHE_FILES["$FINAL_IMG_PATH"]=1
    
    # 若无缓存，生成当前壁纸
    if [ ! -f "$FINAL_IMG_PATH" ]; then
        # 原子写入: waypaper post_command 与本脚本可能并发为同一壁纸生成缓存,
        # 直接写同一路径会互相覆盖导致缓存损坏 (awww img 解码失败)
        TMP_OUT_PATH="$FINAL_IMG_PATH.tmp.$$"
        if [[ -n "$IMG_FILL_COLOR" && -n "$IMG_COLORIZE_STRENGTH" ]]; then
            magick "${img_path}[0]" -auto-orient -resize '2560x2560>' -colorspace sRGB -blur "$IMG_BLUR_STRENGTH" -fill "$IMG_FILL_COLOR" -colorize "$IMG_COLORIZE_STRENGTH" "$TMP_OUT_PATH"
        else
            magick "${img_path}[0]" -auto-orient -resize '2560x2560>' -colorspace sRGB -blur "$IMG_BLUR_STRENGTH" "$TMP_OUT_PATH"
        fi
        
        if [ $? -eq 0 ] && [ -f "$TMP_OUT_PATH" ]; then
            mv -f "$TMP_OUT_PATH" "$FINAL_IMG_PATH"
        else
            rm -f "$TMP_OUT_PATH"
            notify-send "Blur Error" "ImageMagick 生成失败: $FILENAME"
            # 失败则不登记该缓存, 避免 apply_wallpapers 应用不存在的文件
            unset "CACHE_PATHS[$monitor]"
            unset "ACTIVE_CACHE_FILES[$FINAL_IMG_PATH]"
            continue
        fi
    else
        # 刷新访问时间
        touch -a "$FINAL_IMG_PATH"
    fi
done

# ==============================================================================
# 4. 后台维护功能
# ==============================================================================
log() { echo "[$(date '+%H:%M:%S')] $*"; }

target_for() {
    local img="$1"
    local base="${img##*/}"
    echo "$REAL_CACHE_DIR/${PARAM_PREFIX}${base}.jpg"
}

run_maintenance_in_background() {
    (
        declare -A active_wallpapers
        
        # 建立本地目录的白名单
        while IFS= read -r -d '' file; do
            local basename="${file##*/}"
            active_wallpapers["$basename"]=1
        done < <(find -L "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) -print0)

        local orphan_list
        orphan_list=$(mktemp)
        local orphan_count=0
        
        # 寻找孤儿缓存文件
        while IFS= read -r -d '' cache_file; do
            local cache_name="${cache_file##*/}"
            local original_name="${cache_name#${PARAM_PREFIX}}"
            original_name="${original_name%.jpg}"
            
            # 如果原图不在目录中 且 该缓存未在当前屏幕上被使用
            if [[ -z "${active_wallpapers[$original_name]}" ]]; then
                if [[ -z "${ACTIVE_CACHE_FILES[$cache_file]}" ]]; then
                    echo "$cache_file" >> "$orphan_list"
                    orphan_count=$((orphan_count + 1))
                fi
            fi
        done < <(find "$REAL_CACHE_DIR" -maxdepth 1 -name "${PARAM_PREFIX}*" -print0)

        # 删减孤儿文件
        if [[ "$orphan_count" -gt "$ORPHAN_CACHE_LIMIT" ]]; then
            local delete_count=$((orphan_count - ORPHAN_CACHE_LIMIT))
            # 一次性按访问时间升序取最旧的 delete_count 个 (NUL 分隔防特殊字符),
            # 避免 xargs 分批导致每批都删 delete_count 个
            find "$REAL_CACHE_DIR" -maxdepth 1 -name "${PARAM_PREFIX}*" -printf '%A@\t%p\0' \
                | sort -z -k1,1 -n \
                | head -z -n "$delete_count" \
                | while IFS= read -r -d '' line; do
                    rm -f -- "${line#*$'\t'}"
                done
        fi
        rm -f "$orphan_list"

        # 预生成目录下的缓存
        while IFS= read -r -d '' img; do
            local tgt
            tgt=$(target_for "$img")

            # 如果已经被生成过（或是正在使用），则跳过
            if [[ -f "$tgt" ]] || [[ -n "${ACTIVE_CACHE_FILES[$tgt]}" ]]; then
                continue
            fi

            if [[ -n "$IMG_FILL_COLOR" && -n "$IMG_COLORIZE_STRENGTH" ]]; then
                magick "${img}[0]" -auto-orient -resize '2560x2560>' -colorspace sRGB -blur "$IMG_BLUR_STRENGTH" -fill "$IMG_FILL_COLOR" -colorize "$IMG_COLORIZE_STRENGTH" "$tgt.tmp.$$"
            else
                magick "${img}[0]" -auto-orient -resize '2560x2560>' -colorspace sRGB -blur "$IMG_BLUR_STRENGTH" "$tgt.tmp.$$"
            fi
            # 原子落盘: 与前台生成并发时防止写坏缓存文件
            mv -f "$tgt.tmp.$$" "$tgt" 2>/dev/null || rm -f "$tgt.tmp.$$"
        done < <(find -L "$WALL_DIR" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' -o -iname '*.gif' \) -print0)
    ) & 
}

# ==============================================================================
# 5. 应用壁纸逻辑
# ==============================================================================

apply_wallpapers() {
    if [ "$WALLPAPER_BACKEND" == "awww" ]; then
        local daemon_name="awww-daemon"
        
        # layers 输出中名称可能带空格 (awww-daemon overview), 故用 [[:space:]]* 容忍;
        # 再以 pgrep 兜底, 防止 layers 名称不含 overview 时重复拉起 daemon
        if ! { niri msg layers | grep -qiE "${daemon_name}[[:space:]]*overview"; } && ! pgrep -f "$daemon_name -n overview\$" &>/dev/null; then
            # 清理残留 socket: daemon 崩溃/退出可能留下 socket 文件,
            # 新实例启动时会误判"已有实例"而 panic (曾导致 overview 层永久缺失)。
            # 注意: WAYLAND_DISPLAY 已是 "wayland-1" 形式, 路径不能再加 "wayland-" 前缀
            OVERVIEW_SOCKET="$XDG_RUNTIME_DIR/${WAYLAND_DISPLAY}-awww-daemon.overview.sock"

            # 关键: 本脚本可能从 oneshot systemd service (random-api-wallpaper.service)
            # 内部运行。直接在 service 的 cgroup 里拉起 daemon, service 结束时会被
            # KillMode=control-group 一并 SIGTERM (daemon 打印 "Removed socket + Goodbye!"),
            # 导致 overview 模糊背景只在切换壁纸的瞬间存在几秒, 其余时间缺失。
            # daemon 由独立 user service (awww-overview-daemon.service) 托管,
            # systemctl start 幂等: 已运行则为 no-op, 不会重复拉起/panic。
            # flock 串行化: waypaper 的 post_command 与本脚本可能并发调用,
            # 防止两个实例同时做 "检查+启动+清理 socket" 造成竞态。
            local start_lock="$XDG_RUNTIME_DIR/awww-overview-daemon.start.lock"
            exec 9>"$start_lock"
            flock 9
            if ! { niri msg layers | grep -qiE "${daemon_name}[[:space:]]*overview"; } && ! pgrep -f "$daemon_name -n overview\$" &>/dev/null; then
                [ -S "$OVERVIEW_SOCKET" ] && rm -f "$OVERVIEW_SOCKET"
                systemctl --user start awww-overview-daemon.service
            fi
            flock -u 9
            exec 9>&-
            # 等待 daemon 的 socket 就绪再发图: service 冷启动有数百毫秒延迟,
            # 直接 awww img 会抢跑在 socket 创建之前 (报 "Socket file not found")
            for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
                [ -S "$OVERVIEW_SOCKET" ] && break
                sleep 0.2
            done
        fi
        
        # 遍历所有被指定的缓存进行设置
        # 同步执行 (不带 &): 确保图片送达 daemon 后脚本才退出;
        # service 结束时 cgroup 残留进程会被清理, 异步 CLI 可能被杀在半路
        for monitor in "${!CACHE_PATHS[@]}"; do
            img_path="${CACHE_PATHS[$monitor]}"
            if [ "$monitor" == "all" ]; then
                awww img "${AWWW_ARGS[@]}" "$img_path"
            else
                awww img -o "$monitor" "${AWWW_ARGS[@]}" "$img_path"
            fi
        done
        
    elif [ "$WALLPAPER_BACKEND" == "swaybg" ]; then
        if { niri msg layers | grep -qiE "awww-daemon[[:space:]]*overview"; } || pgrep -f "awww-daemon -n overview\$" &>/dev/null; then
            pkill -f "awww-daemon -n overview\$" || true
        fi
        
        # 构造多显示器的 swaybg 参数 (比如: swaybg -o DP-1 -i img1 -o DP-2 -i img2 ...)
        swaybg_args=()
        for monitor in "${!CACHE_PATHS[@]}"; do
            img_path="${CACHE_PATHS[$monitor]}"
            if [ "$monitor" != "all" ]; then
                swaybg_args+=("-o" "$monitor")
            fi
            swaybg_args+=("-i" "$img_path" "-m" "$SWAYBG_MODE")
        done
        
        # 先清理旧 swaybg 实例, 避免多次触发后多个进程互相竞争
        pkill -x swaybg 2>/dev/null || true
        swaybg "${swaybg_args[@]}" &
    fi
}

# ==============================================================================
# 6. 执行与触发
# ==============================================================================

if [ ${#CACHE_PATHS[@]} -eq 0 ]; then
    notify-send "Blur Error" "未找到需要应用的壁纸文件"
    exit 1
fi

apply_wallpapers

if [[ "$AUTO_PREGEN" == "true" ]]; then
    run_maintenance_in_background
fi

exit 0
