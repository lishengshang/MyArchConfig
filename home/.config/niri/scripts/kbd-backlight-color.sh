#!/usr/bin/env fish
# Keyboard backlight color cycler (brightness-preserving)
# 用法: kbd-backlight-color.sh [prev|next]  (无参数默认 next)
set -l LED_DIR /sys/class/leds/rgb:kbd_backlight
set -l LED_FILE $LED_DIR/multi_intensity
set -l BRIGHT_FILE $LED_DIR/brightness
set -l MAX_FILE $LED_DIR/max_brightness

# 非 root 且 multi_intensity 不可写时，通过 sudo 提权重跑自己。
# 依赖 /etc/sudoers.d/kbd-backlight-color 的 NOPASSWD 条目：
#   mio ALL=(root) NOPASSWD: /home/mio/.config/niri/scripts/kbd-backlight-color.sh
if test (id -u) -ne 0
    and not test -w $LED_FILE
    sudo -n (status filename) $argv
    if test $status -ne 0
        notify-send -u critical "键盘背光" "提权失败：请配置 /etc/sudoers.d/kbd-backlight-color"
        exit 1
    end
    exit 0
end

set -l colors \
   "255 255 255" \
   "255 128 64" \
   "255 200 0" \
   "255 80 80" \
   "255 0 128" \
   "180 0 255" \
   "0 128 255" \
   "0 255 200" \
   "0 255 64"

# 当前各通道值、当前亮度、最大亮度
set -l current (string split " " -- (cat $LED_FILE 2>/dev/null))
set -l brightness (cat $BRIGHT_FILE 2>/dev/null)
set -l max_brightness (cat $MAX_FILE 2>/dev/null)

if test (count $current) -ne 3 -o -z "$brightness" -o -z "$max_brightness" -o "$max_brightness" -eq 0
    exit 1
end

# 归一化：按当前通道最大值放大回满亮度。
# 亮度变化（brightnessctl 走固件）不会改动 multi_intensity，但脚本自己写入的是缩放值，
# 统一按 max(raw) 放大后，两种状态都能匹配回色板。
set -l max_current 0
for c in $current
    if test "$c" -gt "$max_current"
        set max_current $c
    end
end

set -l norm
if test "$max_current" -gt 0
    for c in $current
        set -a norm (math -s0 "round($c * $max_brightness / $max_current)")
    end
else
    set norm $current
end

set -l total (count $colors)
set -l idx 1
set -l found false

# 容差 ±2，避免缩放取整导致的 ±1 误差
for i in (seq 1 $total)
    set -l pal (string split " " -- $colors[$i])
    set -l ok true
    for j in (seq 1 3)
        if test (math -s0 "abs($pal[$j] - $norm[$j])") -gt 2
            set ok false
            break
        end
    end
    if test "$ok" = true
        set found true
        set idx $i
        break
    end
end

if test "$argv[1]" = prev
    set idx (math "$idx - 1")
    if test "$idx" -lt 1
        set idx $total
    end
else
    set idx (math "$idx + 1")
    if test "$idx" -gt $total
        set idx 1
    end
end

# 把色板颜色按当前亮度缩放后写入，换色不会把亮度顶回 100%
set -l out
for c in (string split " " -- $colors[$idx])
    set -a out (math -s0 "round($c * $brightness / $max_brightness)")
end

if not echo (string join " " -- $out) > $LED_FILE
    notify-send -u critical "键盘背光" "写入 $LED_FILE 失败（权限不足？请检查 udev 规则）"
    exit 1
end
