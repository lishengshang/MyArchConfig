#!/bin/bash
set -Eeuo pipefail

GENERATED_COLORS="$HOME/.cache/matugen_vscode_inject.json"

# 支持的 VS Code 变体：包名 -> 配置目录名
declare -A VARIANTS=(
    ["visual-studio-code"]="Code"
    ["visual-studio-code-bin"]="Code"
    ["code"]="Code - OSS"
    ["code-oss"]="Code - OSS"
    ["vscodium"]="VSCodium"
    ["vscodium-bin"]="VSCodium"
)

injected=0

if [[ ! -r "$GENERATED_COLORS" ]]; then
    echo "⚠️ Generated VS Code colors not found: $GENERATED_COLORS"
    exit 0
fi

for pkg in "${!VARIANTS[@]}"; do
    config_dir="${VARIANTS[$pkg]}"
    # pacman -Qq accepts package provides (for example `code` is provided by
    # visual-studio-code-bin). Match the installed package name exactly so a
    # VS Code OSS directory is not probed when only the binary package exists.
    if pacman -Qq 2>/dev/null | grep -Fx "$pkg" >/dev/null; then
        user_dir="$HOME/.config/$config_dir/User"
        base_settings="$user_dir/settings.base.json"
        vscode_settings="$user_dir/settings.json"

        if [[ ! -r "$base_settings" ]]; then
            echo "⚠️ Base VS Code settings not found: $base_settings"
            continue
        fi

        mkdir -p "$user_dir"

        # settings.json 是 Matugen 生成的本地文件，不再写穿 Stow 软链。
        # 第一次运行时从 Git 管理的 settings.base.json 创建它。
        if [[ -L "$vscode_settings" ]]; then
            rm -f "$vscode_settings"
        fi
        if [[ ! -f "$vscode_settings" ]]; then
            cp -- "$base_settings" "$vscode_settings"
        fi

        tmp=$(mktemp "$user_dir/settings.json.tmp.XXXXXX")
        if jq -s '.[0] * .[1]' "$vscode_settings" "$GENERATED_COLORS" > "$tmp"; then
            mv -f -- "$tmp" "$vscode_settings"
            echo "✅ VS Code colors updated for $pkg ($config_dir)."
            injected=$((injected + 1))
        else
            echo "❌ Injection failed for $pkg ($config_dir)."
            rm -f -- "$tmp"
        fi
    fi
done

if [[ "$injected" -eq 0 ]]; then
    echo "⚠️ No supported VS Code variant found (visual-studio-code, code, vscodium, etc.). Skipping injection."
fi
