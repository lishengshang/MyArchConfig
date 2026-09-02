#!/bin/bash
# 随机下载动漫壁纸并应用 (Mod+Shift+F10)。
# 依赖 wallpaper-lib.sh (同目录公共库): 锁 / 通知 / waypaper 同步 / 主题后处理。

# ================= 默认配置 =================
# 源池: name|url|extractor
#   extractor 为空 = 直出图源 (url 即图片地址)
#   extractor 非空 = JSON API 源: 先 curl url, 再用 jq -r extractor 提取图片地址
#   占位符 (仅 extractor/url 内有效): {{PAGE:N}} = 随机页 1..N, {{RANDOM}} = 随机索引 0..23
SOURCES=(
    "dmoe|https://www.dmoe.cc/random.php|"
    "paugram|https://api.paugram.com/wallpaper/?source=sina|"
    "paiii|https://t.paiii.cn/api/random|"
    "yppp|https://api.yppp.net/pc.php|"
    "uapis|https://uapis.cn/api/v1/random/image?category=acg&type=pc|"
    "touhou|https://img.paulzzh.com/touhou/random?size=pc|"
    "anosu|https://api.anosu.top/img|"
    "zhuqiy|https://rimg.zhuqiy.top/api/random?type=pc|"
    "horosama|https://api.horosama.com/random.php?type=pc|"
    "98qy|https://www.98qy.com/sjbz/api.php?method=pc&lx=dongman|"
    "mwm-pc|https://t.mwm.moe/pc|"
    "mwm-fj|https://t.mwm.moe/fj|"
    "xl0408|https://imgapi.xl0408.top/index.php|"
    "r10086|https://api.r10086.com/%E6%A8%B1%E9%81%93%E9%9A%8F%E6%9C%BA%E5%9B%BE%E7%89%87api%E6%8E%A5%E5%8F%A3.php?%E5%9B%BE%E7%89%87%E7%B3%BB%E5%88%97=%E5%8A%A8%E6%BC%AB%E7%BB%BC%E5%90%881|"
    "loliapi|https://www.loliapi.com/acg/?type=pc|"
    "suyanw|https://api.suyanw.cn/api/comic/api.php|"
    "jitsu|https://moe.jitsu.top/api/?size=pc|"
    "yande|https://yande.re/post.json?tags=rating:safe+width:%3E=1920+score:%3E=15+order:random&limit=1|.[0].file_url"
    "wallhaven|https://wallhaven.cc/api/v1/search?categories=010&purity=100&sorting=toplist&topRange=3M&atleast=1920x1080&ratios=16x9,16x10&q=-ai%20art&page={{PAGE:10}}|.data[{{RANDOM}}].path"
    "wallhaven-hot|https://wallhaven.cc/api/v1/search?categories=010&purity=100&sorting=toplist&topRange=1M&atleast=1920x1080&ratios=16x9,16x10&q=-ai%20art&page={{PAGE:3}}|.data[{{RANDOM}}].path"
)

# 保底源: 其他源全部失败后再尝试
FALLBACK_SOURCE="alcy|https://t.alcy.cc/pc/|"

SAVE_DIR="$HOME/Pictures/Wallpapers/api-random-download"

# 最近使用过的源记录, 选源时跳过最近 RECENT_EXCLUDE_COUNT 次, 避免短时间重复
RECENT_SOURCES_FILE="$SAVE_DIR/.recent_sources"
RECENT_EXCLUDE_COUNT=3

# 自动清理时保留最近多少张图片
KEEP_COUNT=1000

# 最小宽度: 低于此宽度的图片直接丢弃 (防低清图)
MIN_WIDTH=1280

# 超分判断基准宽度: 取不到显示器分辨率时的 fallback 值
FALLBACK_TARGET_WIDTH=2200

# 图片宽度达到目标宽度的多少百分比才免于超分 (留余量避免小幅放大浪费 GPU)
UPSCALE_RATIO=90

# 增量哈希去重缓存: "hash  size:mtime  path" 三元组按行存储。
# 只对 size/mtime 变化的文件重新计算哈希, 避免每次下载前全库扫描 (随图库增长线性变贵)。
HASH_CACHE_FILE="$SAVE_DIR/.wall_hashes"

# 失败降级: 最多尝试多少个源
MAX_SOURCE_ATTEMPTS=3

# 默认开关状态 (可被参数覆盖)
ENABLE_CLEANUP=true   # 默认清理旧图片
ENABLE_UPSCALE=true   # 默认开启智能超分
SILENT_MODE=false     # 默认开启通知
FORCED_SOURCE=""      # 默认随机; 用 -S <name> 指定

# ================= 公共库 =================
# 经 stow symlink 调用时解析到 dotfiles 仓库内的真实目录
SCRIPT_DIR="$(cd -- "$(dirname -- "$(readlink -f -- "${BASH_SOURCE[0]}")")" && pwd)"
# shellcheck source=wallpaper-lib.sh
source "$SCRIPT_DIR/wallpaper-lib.sh"
WALLPAPER_SILENT=$SILENT_MODE

# ImageMagick 7 优先, 回退 ImageMagick 6
if command -v magick &> /dev/null; then
    MAGICK_CMD="magick"
elif command -v convert &> /dev/null; then
    MAGICK_CMD="convert"
else
    MAGICK_CMD=""
fi

# 超分工具: 优先 Real-ESRGAN (realesr-animevideov3 为二次元图优化, 且速度更快),
# waifu2x 仅作后备
if command -v realesrgan-ncnn-vulkan &> /dev/null; then
    UPSCALE_TOOL="realesrgan"
elif command -v waifu2x-ncnn-vulkan &> /dev/null; then
    UPSCALE_TOOL="waifu2x"
else
    UPSCALE_TOOL=""
fi

# ================= 参数解析 =================
usage() {
    echo "用法: $(basename $0) [-k] [-n] [-s] [-S <name>] [-h]"
    echo "  -k           (Keep)    保留模式: 不清理旧壁纸"
    echo "  -n           (No Up)  禁用超分: 无论分辨率多少,都直接使用原图"
    echo "  -s           (Silent) 静默模式: 不发送任何 notify-send 通知"
    echo "  -S <name>    (Source) 指定使用某个源 (${SOURCES[*]//|*/ } ${FALLBACK_SOURCE%%|*})"
    echo "  -h           帮助信息"
    exit 0
}

while getopts "knS:sh" opt; do
  case $opt in
    k) ENABLE_CLEANUP=false ;;
    n) ENABLE_UPSCALE=false ;;
    s) SILENT_MODE=true; WALLPAPER_SILENT=true ;;
    S) FORCED_SOURCE="$OPTARG" ;;
    h) usage ;;
    *) usage ;;
  esac
done

# ================= 辅助函数 =================

# 校验下载结果: 文件存在 + 大小 >= 20KB + MIME 是 image/*
# 用法: validate_image <path>  -> 返回 0 成功 / 1 失败
validate_image() {
    local f="$1"
    [ -f "$f" ] || return 1
    [ "$(wc -c < "$f")" -ge 20480 ] || return 1
    local mime
    mime=$(file --mime-type -b "$f")
    [[ "$mime" == image/* ]] || return 1
    return 0
}

# 校验几何: 拒绝竖图与过小图片 (identify 不可用时跳过, 交给下游)
# 用法: validate_geometry <path>  -> 返回 0 通过 / 1 拒绝; 同时回填全局 IMG_WIDTH/IMG_HEIGHT
# (供超分判断复用, 避免对同一文件重复调 identify)
validate_geometry() {
    local f="$1" dims w h
    IMG_WIDTH=0
    IMG_HEIGHT=0
    command -v identify &> /dev/null || return 0
    dims=$(identify -format "%w %h" "$f" 2>/dev/null)
    w="${dims%% *}"
    h="${dims##* }"
    [[ "$w" =~ ^[0-9]+$ && "$h" =~ ^[0-9]+$ ]] || return 0
    IMG_WIDTH="$w"
    IMG_HEIGHT="$h"
    [ "$h" -le "$w" ] || return 1
    [ "$w" -ge "$MIN_WIDTH" ] || return 1
    return 0
}

# 统一转 JPG: 非 JPEG 内容用 ImageMagick 重编码 (quality 93, auto-orient 纠正 EXIF 旋转),
# 保证下游 (超分/waypaper/清理/随机切换) 只处理一种格式。转换失败返回 1, 由调用方丢弃。
# 用法: normalize_to_jpg <path>  -> 返回 0 成功 / 1 失败
normalize_to_jpg() {
    local f="$1"
    [ "$(file --mime-type -b "$f" 2>/dev/null)" = image/jpeg ] && return 0
    [ -n "$MAGICK_CMD" ] || return 1
    local tmp="${f%.jpg}.norm.jpg"
    "$MAGICK_CMD" "$f" -auto-orient -quality 93 "$tmp" 2>/dev/null || return 1
    mv -f "$tmp" "$f"
    return 0
}

# 目标宽度: 优先取当前会话所有显示器的最大物理分辨率 (niri),
# 取不到时退回 FALLBACK_TARGET_WIDTH
get_target_width() {
    local w
    w=$(niri msg -j outputs 2>/dev/null \
        | jq -r '[.[] | .modes[.current_mode].width] | max // empty' 2>/dev/null)
    if [ -n "$w" ] && [ "$w" -gt 0 ] 2>/dev/null; then
        printf '%s' "$w"
    else
        printf '%s' "$FALLBACK_TARGET_WIDTH"
    fi
}

# 从源池构造本次尝试顺序 (随机打乱,或把指定源放最前,保底源永远最后)
# 随机模式下跳过最近 RECENT_EXCLUDE_COUNT 次用过的源, 避免短时间重复;
# 若过滤后源池为空 (源太少或刚好用完一圈), 退化为全随机保证可用性。
# 输出 stdout: 每行一个 "name|url";返回 1 表示 FORCED_SOURCE 不存在
build_source_order() {
    local fallback_name="${FALLBACK_SOURCE%%|*}"
    if [ -n "$FORCED_SOURCE" ]; then
        local found=""
        for s in "${SOURCES[@]}"; do
            if [ "${s%%|*}" = "$FORCED_SOURCE" ]; then
                found="$s"
                break
            fi
        done
        [ -z "$found" ] && return 1
        echo "$found"
        for s in "${SOURCES[@]}"; do
            [ "$s" = "$found" ] && continue
            echo "$s"
        done | shuf
        # 保底源放在最后
        [ "$fallback_name" != "$FORCED_SOURCE" ] && echo "$FALLBACK_SOURCE"
        return
    fi
    # 随机模式: 过滤掉最近用过的源
    local recent pool=() s name
    recent=$(cat "$RECENT_SOURCES_FILE" 2>/dev/null)
    for s in "${SOURCES[@]}"; do
        name="${s%%|*}"
        if printf '%s\n' "$recent" | grep -qxF -- "$name"; then
            continue
        fi
        pool+=("$s")
    done
    if [ ${#pool[@]} -eq 0 ]; then
        printf '%s\n' "${SOURCES[@]}" | shuf
    else
        printf '%s\n' "${pool[@]}" | shuf
    fi
    echo "$FALLBACK_SOURCE"
}

# 记录本次使用的源, 保留最近 RECENT_EXCLUDE_COUNT 个 (保底源不记录, "保底除外")
# 用法: record_source <name>
record_source() {
    local name="$1"
    [ -z "$name" ] && return 0
    local tmp
    tmp=$(mktemp)
    { [ -f "$RECENT_SOURCES_FILE" ] && cat "$RECENT_SOURCES_FILE"; echo "$name"; } \
        | tail -n "$RECENT_EXCLUDE_COUNT" > "$tmp"
    mv "$tmp" "$RECENT_SOURCES_FILE"
}

# ================= 主逻辑 =================

mkdir -p "$SAVE_DIR"

# 单实例锁: timer 与手动调用并发时, 防止互踩下载文件与 waypaper 配置 (公共库 flock)
if ! wallpaper_lock_acquire "wallpaper-switch"; then
    exit 0
fi

# 预加载去重哈希缓存 (增量维护), 用于下载去重。
# 全局关联数组: HASH_CACHE[path]=hash, SIG_CACHE[path]="size:mtime"。
# mktemp 失败 (极少见) 时降级为空缓存, 本次对所有文件重算哈希。
declare -A HASH_CACHE=() SIG_CACHE=()
NEW_ENTRIES=$(mktemp 2>/dev/null || true)
load_hash_cache() {
    local line f sig hash rest
    [ -f "$HASH_CACHE_FILE" ] || return 0
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        hash="${line%% *}"
        rest="${line#* }"
        sig="${rest%% *}"
        f="${rest#* }"
        HASH_CACHE["$f"]="$hash"
        SIG_CACHE["$f"]="$sig"
    done < "$HASH_CACHE_FILE"
}
# 刷新缓存: 对当前每个文件复用旧哈希或重算 (仅 size/mtime 变化才重算),
# 被清理/删除的文件自然淘汰。结果原子替换缓存文件。
refresh_hash_cache() {
    local f sig old hash
    # 首次调用后临时文件已消耗, 后续调用重新建一个 (结尾还要补登新文件)
    [ -n "$NEW_ENTRIES" ] || NEW_ENTRIES=$(mktemp 2>/dev/null || true)
    [ -n "$NEW_ENTRIES" ] || return 0
    : > "$NEW_ENTRIES"
    while IFS= read -r -d '' f; do
        sig=$(stat -c '%s:%Y' "$f" 2>/dev/null) || continue
        old="${SIG_CACHE[$f]:-}"
        if [ "$old" = "$sig" ] && [ -n "${HASH_CACHE[$f]:-}" ]; then
            printf '%s %s %s\n' "${HASH_CACHE[$f]}" "$sig" "$f" >> "$NEW_ENTRIES"
        else
            hash=$(sha256sum "$f" | cut -d' ' -f1)
            printf '%s %s %s\n' "$hash" "$sig" "$f" >> "$NEW_ENTRIES"
            HASH_CACHE["$f"]="$hash"
            SIG_CACHE["$f"]="$sig"
        fi
    done < <(find "$SAVE_DIR" -maxdepth 1 -type f -name 'wall_*' -print0 2>/dev/null)
    mv -f "$NEW_ENTRIES" "$HASH_CACHE_FILE" 2>/dev/null || rm -f "$NEW_ENTRIES"
    NEW_ENTRIES=""
}
trap 'rm -f "$NEW_ENTRIES"' EXIT
load_hash_cache
refresh_hash_cache

# 统一 JPG: 下载内容先重编码, 文件名后缀与真实格式始终一致
RAW_PATH="${SAVE_DIR}/wall_$(date +%s%N)_$$.jpg"

USER_AGENT="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

# --- 1. 下载模块 (带心跳通知 + 多源降级) ---

if [ "$SILENT_MODE" = false ]; then
    (
        sleep 8
        while true; do
            notify-send "壁纸" "壁纸下载仍在进行中..." --expire-time=5000 --icon=drive-harddisk --replace-id=999
            sleep 8
        done
    ) &
    NOTIFY_PID=$!
else
    NOTIFY_PID=""
fi

wallpaper_notify "壁纸" "正在下载壁纸..." "--expire-time=5000"

# 构造源尝试顺序
SOURCE_ORDER=$(build_source_order)
if [ $? -ne 0 ]; then
    echo "错误: 未知源 '$FORCED_SOURCE'" >&2
    echo "可用源: ${SOURCES[*]//|*/ }" >&2
    wallpaper_notify "壁纸错误" "未知图源: $FORCED_SOURCE" "--urgency=critical"
    exit 1
fi
ATTEMPT_COUNT=0
DOWNLOAD_OK=false
USED_SOURCE_NAME=""

# 依次尝试,最多 MAX_SOURCE_ATTEMPTS 个源,首个成功即用
while IFS= read -r entry; do
    [ -z "$entry" ] && continue
    ATTEMPT_COUNT=$((ATTEMPT_COUNT + 1))
    if [ "$ATTEMPT_COUNT" -gt "$MAX_SOURCE_ATTEMPTS" ]; then
        break
    fi

    SRC_NAME="${entry%%|*}"
    SRC_REST="${entry#*|}"
    SRC_URL="${SRC_REST%%|*}"
    SRC_EXTRACT=""
    [ "$SRC_REST" != "$SRC_URL" ] && SRC_EXTRACT="${SRC_REST#*|}"

    wallpaper_notify "壁纸" "正在尝试 [$SRC_NAME] ($ATTEMPT_COUNT/$MAX_SOURCE_ATTEMPTS)..." "--expire-time=3000"

    DOWNLOAD_URL="$SRC_URL"
    if [ -n "$SRC_EXTRACT" ]; then
        if ! command -v jq &> /dev/null; then
            echo "跳过 [$SRC_NAME]: 缺少 jq" >&2
            rm -f "$RAW_PATH"
            continue
        fi
        wallpaper_notify "壁纸" "正在查询 [$SRC_NAME] API..." "--expire-time=3000"
        API_URL="$SRC_URL"
        P_SPEC=$(printf '%s' "$API_URL" | sed -n 's/.*{{PAGE:\([0-9]*\)}}.*/\1/p')
        [ -n "$P_SPEC" ] && API_URL=$(printf '%s' "$API_URL" | sed "s|{{PAGE:$P_SPEC}}|$((RANDOM % P_SPEC + 1))|")
        EXPR="$SRC_EXTRACT"
        case "$EXPR" in
            *'{{RANDOM}}'*) EXPR=$(printf '%s' "$EXPR" | sed "s|{{RANDOM}}|$((RANDOM % 24))|") ;;
        esac
        DOWNLOAD_URL=$(curl -L -f -s -A "$USER_AGENT" --connect-timeout 10 -m 30 "$API_URL" | jq -r "$EXPR" 2>/dev/null)
        case "$DOWNLOAD_URL" in
            http*) ;;
            *) rm -f "$RAW_PATH"; continue ;;
        esac
    fi

    curl -L -f -s -A "$USER_AGENT" --connect-timeout 10 -m 120 -o "$RAW_PATH" "$DOWNLOAD_URL"
    CURL_EXIT=$?

    if [ $CURL_EXIT -eq 0 ] && normalize_to_jpg "$RAW_PATH" \
        && validate_image "$RAW_PATH" && validate_geometry "$RAW_PATH"; then
        HASH=$(sha256sum "$RAW_PATH" | cut -d' ' -f1)
        if printf '%s\n' "${HASH_CACHE[@]}" | grep -qFx -- "$HASH"; then
            rm -f "$RAW_PATH"
            continue
        fi
        DOWNLOAD_OK=true
        USED_SOURCE_NAME="$SRC_NAME"
        record_source "$SRC_NAME"
        break
    fi

    rm -f "$RAW_PATH"
done <<< "$SOURCE_ORDER"

# 保底源: 主循环只尝试前 MAX_SOURCE_ATTEMPTS 个, fallback 排在最后轮不到,
# 必须在循环结束后单独尝试
if [ "$DOWNLOAD_OK" = false ] && [ -n "$FALLBACK_SOURCE" ]; then
    FALLBACK_NAME="${FALLBACK_SOURCE%%|*}"
    FALLBACK_REST="${FALLBACK_SOURCE#*|}"
    FALLBACK_URL="${FALLBACK_REST%%|*}"
    wallpaper_notify "壁纸" "正在尝试保底源 [$FALLBACK_NAME]..." "--expire-time=3000"

    curl -L -f -s -A "$USER_AGENT" --connect-timeout 10 -m 120 -o "$RAW_PATH" "$FALLBACK_URL"
    CURL_EXIT=$?

    if [ $CURL_EXIT -eq 0 ] && normalize_to_jpg "$RAW_PATH" \
        && validate_image "$RAW_PATH" && validate_geometry "$RAW_PATH"; then
        DOWNLOAD_OK=true
        USED_SOURCE_NAME="$FALLBACK_NAME"
    else
        rm -f "$RAW_PATH"
    fi
fi

# 文件名附带源名 (wall_<source>_<ts>.jpg): 日后从文件名即可判断哪些图源产出可用壁纸。
# 后续超分/去重/清理均基于 RAW_PATH 变量与 wall_* 通配符, 重命名不影响它们。
if [ "$DOWNLOAD_OK" = true ] && [ -n "$USED_SOURCE_NAME" ]; then
    NAMED_PATH="${SAVE_DIR}/wall_${USED_SOURCE_NAME}_$(date +%s%N)_$$.jpg"
    if mv -f "$RAW_PATH" "$NAMED_PATH" 2>/dev/null; then
        RAW_PATH="$NAMED_PATH"
    fi
fi

# 下载结束,杀掉心跳通知进程
if [ -n "$NOTIFY_PID" ]; then
    kill "$NOTIFY_PID" 2>/dev/null
    wait "$NOTIFY_PID" 2>/dev/null
fi

if [ "$DOWNLOAD_OK" = false ]; then
    wallpaper_notify "壁纸错误" "所有图源在 $MAX_SOURCE_ATTEMPTS 次尝试后均失败" "--urgency=critical"
    rm -f "$RAW_PATH"
    exit 1
fi

# --- 2. 智能超分模块 (目标宽度 = 显示器实际分辨率) ---

FINAL_PATH="$RAW_PATH"
MSG_EXTRA="来自 $USED_SOURCE_NAME"

if [ "$ENABLE_UPSCALE" = true ] && [ -n "$UPSCALE_TOOL" ]; then
    # IMG_WIDTH/IMG_HEIGHT 已由 validate_geometry 回填, 无需再次 identify

    TARGET_WIDTH=$(get_target_width)
    # 仅对横屏且宽度不足目标宽度 UPSCALE_RATIO% 的图超分 (竖图已被 validate_geometry 拦截)
    if [ "$IMG_WIDTH" -gt 0 ] && [ "$IMG_HEIGHT" -gt 0 ] \
        && [ "$IMG_HEIGHT" -le "$IMG_WIDTH" ] \
        && [ $((IMG_WIDTH * 100)) -lt $((TARGET_WIDTH * UPSCALE_RATIO)) ]; then
        wallpaper_notify "壁纸" "正在超分放大图片 (目标宽度 $TARGET_WIDTH)..." "--expire-time=2000"

        if [ "$UPSCALE_TOOL" = realesrgan ]; then
            # realesr-animevideov3: 二次元模型, -s 2 输出 2x; 直出 jpg 省掉大体积 PNG 中转的读写与重编码;
            # 失败则退回 PNG + 转码路径, 保证可用性不降级。
            UPSCALED_PATH="${RAW_PATH%.jpg}.upscaled.jpg"
            UPSCALE_OK=false
            if realesrgan-ncnn-vulkan -i "$RAW_PATH" -o "$UPSCALED_PATH" \
                -n realesr-animevideov3 -s 2 -f jpg; then
                UPSCALE_OK=true
                FINAL_PATH="$UPSCALED_PATH"
            fi
            if [ "$UPSCALE_OK" = false ]; then
                rm -f "$UPSCALED_PATH"
                UPSCALED_PATH="${RAW_PATH%.jpg}.upscaled.png"
                realesrgan-ncnn-vulkan -i "$RAW_PATH" -o "$UPSCALED_PATH" \
                    -n realesr-animevideov3 -s 2 -f png && UPSCALE_OK=true
            fi
        else
            UPSCALED_PATH="${RAW_PATH%.jpg}.upscaled.png"
            UPSCALE_OK=false
            waifu2x-ncnn-vulkan -i "$RAW_PATH" -o "$UPSCALED_PATH" -n 1 -s 2 && UPSCALE_OK=true
        fi

        if [ "$UPSCALE_OK" = true ] && [ "$UPSCALED_PATH" != "$FINAL_PATH" ]; then
            # PNG 路径: 体积大, 统一转回 JPG; 转换失败则退回 PNG。
            # (realesrgan 直出 jpg 成功时 FINAL_PATH 已是最终文件, 跳过此步)
            if [ -n "$MAGICK_CMD" ] && "$MAGICK_CMD" "$UPSCALED_PATH" -quality 93 "$RAW_PATH" 2>/dev/null; then
                rm -f "$UPSCALED_PATH"
                FINAL_PATH="$RAW_PATH"
            else
                FINAL_PATH="$UPSCALED_PATH"
            fi
        fi

        if [ "$UPSCALE_OK" = true ]; then
            # 超分产物替代原图时必须删除原图, 否则库里会同时留下
            # 原图与超分版两张内容相同的照片 (用户视角即“重复壁纸”)。
            # 覆盖两种路径: 直出 jpg / PNG 转码失败退回 PNG。
            if [ "$FINAL_PATH" != "$RAW_PATH" ]; then
                rm -f "$RAW_PATH"
            fi
            MSG_EXTRA="$MSG_EXTRA (已超分 2x)"
        else
            MSG_EXTRA="$MSG_EXTRA (超分失败)"
        fi
    elif [ "$IMG_WIDTH" -gt 0 ]; then
        if [ "$IMG_WIDTH" -ge "$TARGET_WIDTH" ]; then
            MSG_EXTRA="$MSG_EXTRA (原图高分辨率)"
        else
            MSG_EXTRA="$MSG_EXTRA (原图)"
        fi
    fi
elif [ "$ENABLE_UPSCALE" = true ]; then
    MSG_EXTRA="$MSG_EXTRA (超分已禁用: 缺少 realesrgan/waifu2x)"
else
    MSG_EXTRA="$MSG_EXTRA (超分已禁用)"
fi

# --- 3. 应用模块 ---

if ! awww img "$FINAL_PATH" --transition-duration 2 --transition-type center --transition-fps 60; then
    wallpaper_notify "壁纸错误" "awww 应用壁纸失败" "--urgency=critical"
    # 清理本次下载的文件, 避免残留
    rm -f "$RAW_PATH"
    [ "$FINAL_PATH" != "$RAW_PATH" ] && rm -f "$FINAL_PATH"
    exit 1
fi

# 同步 waypaper 状态 (公共库): 本脚本绕过 waypaper 直接调用 awww,
# 需手动更新 waypaper 的当前壁纸记录, 否则 waypaper GUI 显示的"当前壁纸"会过期,
# matugen-update.sh / niri_set_overview_blur_dark_bg.sh 的 fallback 分支也会读到错误的壁纸路径.
wallpaper_sync_waypaper "$FINAL_PATH"

# --- 4. 钩子与清理 ---

# 颜色提取和模糊背景生成统一交给异步 worker (公共库)，避免切换快捷键等待
# ImageMagick，也避免与 waypaper 的 post_command 重复执行。
wallpaper_run_post_command

# 超分产物是新文件, 补登到哈希缓存, 下次下载去重时不再重算全库。
refresh_hash_cache

(
    # 动态清理逻辑: 保留最近 KEEP_COUNT 张,按修改时间倒序
    # 用 find -printf + NUL 分隔处理文件名特殊字符;${line#* } 跳过 mtime 字段;
    # xargs 批量 rm 避免逐文件 fork
    if [ "$ENABLE_CLEANUP" = true ]; then
        DELETE_START=$((KEEP_COUNT + 1))
        # 只清理脚本下载的 wall_* 文件, 豁免手动放入的精选图 (如 01-alcy-pc_*.webp)
        find "$SAVE_DIR" -maxdepth 1 -type f -name 'wall_*' -printf '%T@ %p\0' \
            | sort -z -k1,1 -rn \
            | tail -z -n +"$DELETE_START" \
            | sed -z 's/^[^ ]* //' \
            | xargs -0 -r rm -f --
    fi
) &

wallpaper_notify "壁纸已更新" "Enjoy! $MSG_EXTRA"
