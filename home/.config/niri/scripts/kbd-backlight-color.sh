#!/usr/bin/env fish
# Keyboard backlight color cycler
set -l LED_PATH /sys/class/leds/rgb:kbd_backlight/multi_intensity

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

set -l current (cat $LED_PATH 2>/dev/null)
if test -z "$current"
    exit 1
end

set -l total (count $colors)
set -l idx 1
set -l found false

for i in (seq 1 $total)
    if test "$current" = "$colors[$i]"
        set found true
        set idx $i
        break
    end
end

if test "$found" = false
    set idx 1
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

echo $colors[$idx] > $LED_PATH
