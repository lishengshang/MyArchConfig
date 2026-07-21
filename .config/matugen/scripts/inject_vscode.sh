#!/bin/bash

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

for pkg in "${!VARIANTS[@]}"; do
    config_dir="${VARIANTS[$pkg]}"
    if pacman -Qq "$pkg" >/dev/null 2>&1; then
        VSCODE_SETTINGS="$HOME/.config/$config_dir/User/settings.json"

        if [ ! -f "$VSCODE_SETTINGS" ]; then
            mkdir -p "$(dirname "$VSCODE_SETTINGS")"
            echo "{}" > "$VSCODE_SETTINGS"
        fi

        tmp=$(mktemp)
        if jq -s '.[0] * .[1]' "$VSCODE_SETTINGS" "$GENERATED_COLORS" > "$tmp"; then
            mv "$tmp" "$VSCODE_SETTINGS"
            echo "✅ VS Code colors updated for $pkg ($config_dir)."
            injected=$((injected + 1))
        else
            echo "❌ Injection failed for $pkg ($config_dir)."
            rm -f "$tmp"
        fi
    fi
done

if [ "$injected" -eq 0 ]; then
    echo "⚠️ No supported VS Code variant found (visual-studio-code, code, vscodium, etc.). Skipping injection."
fi
