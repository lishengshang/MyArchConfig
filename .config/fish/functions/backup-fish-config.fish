function backup-fish-config -d "Backup current fish configuration"
    set -l backup_dir "$HOME/.config/fish.backup."(date +%Y%m%d_%H%M%S)
    cp -r ~/.config/fish $backup_dir
    echo "Fish 配置已备份到: $backup_dir"
end
