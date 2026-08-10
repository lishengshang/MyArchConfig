#!/bin/bash

# 你的设备 ID，保持不变
DEVICE="i2c-FTCS1000:01"
FLAG_FILE="/tmp/touchpad-disabled"

# 关键修改：直接使用 sudo tee，配合后续的 NOPASSWD 配置
BIND_CMD="sudo tee /sys/bus/i2c/drivers/i2c_hid_acpi/bind"
UNBIND_CMD="sudo tee /sys/bus/i2c/drivers/i2c_hid_acpi/unbind"

if [ -f "$FLAG_FILE" ]; then
    echo -n "$DEVICE" | $BIND_CMD > /dev/null
    rm "$FLAG_FILE"
    notify-send "触控板状态" "已启用" -t 1000  # 桌面通知
else
    echo -n "$DEVICE" | $UNBIND_CMD > /dev/null
    touch "$FLAG_FILE"
    notify-send "触控板状态" "已禁用" -t 1000
fi