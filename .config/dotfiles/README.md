# lss 的 Arch dotfiles

基于 bare git repo 的现代 dotfiles 管理方案。

## 主要特性

- **裸仓库管理**: `~/.cfg` 作为 GIT_DIR，`$HOME` 作为 worktree，零额外依赖
- **白名单策略**: `~/.gitignore` 默认 `/*` 忽略一切，按需白名单配置目录
- **新机器一键恢复**: `setup.sh` 完成初始化，`bootstrap.sh` 装依赖包
- **包列表自动生成**: `pkglist.txt` + `foreign-pkglist.txt` 记录已装软件
- **缓存文件不跟踪**: fish completions、zcompdump、cached_layouts 等自动生成物不进仓库

## 仓库布局

```
~/
├── .cfg/                          # 裸仓库内部文件（GIT_DIR，不要手动改）
├── .gitignore                     # dotfiles 仓库的 gitignore（白名单策略）
├── .zshenv                        # zsh 入口，设置 ZDOTDIR
├── .p10k.zsh                      # Powerlevel10k 主题
└── .config/
    ├── dotfiles/                  # ← 你正在看的目录，受版本控制
    │   ├── README.md              # 主文档
    │   ├── HOW.md                 # 详细使用手册
    │   ├── setup.sh               # 新机器一键初始化
    │   ├── bootstrap.sh           # 装包脚本
    │   ├── update-pkglist.sh      # 重新生成包列表
    │   ├── pkglist.txt            # pacman 原生包列表（自动生成）
    │   └── foreign-pkglist.txt     # AUR 包列表（自动生成）
    ├── zsh/                       # zsh 配置（ZDOTDIR）
    ├── fish/                      # fish 配置（备用 shell）
    ├── niri/                      # Niri 窗口管理器
    ├── nvim/                      # Neovim (LazyVim)
    ├── kitty/                    # Kitty 终端
    ├── ghostty/                  # Ghostty 终端
    ├── waybar/                   # 状态栏
    ├── mako/                     # 通知
    └── ...                       # 其他配置目录
```

## 快速开始

### 在新机器上恢复

```bash
# 1. clone + checkout（处理冲突文件备份）
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/.config/dotfiles/setup.sh)

# 2. 装包（可选）
bash ~/.config/dotfiles/bootstrap.sh

# 3. 重新加载 shell
exec zsh
```

详见 [HOW.md](HOW.md)。

### 日常使用

```bash
dot status          # 看哪些文件有变动
dot diff            # 看具体改了什么
dot add .config/foo # 跟踪新文件（要先在 .gitignore 白名单里）
dot commit -m "xxx" # 提交
dot push            # 推到 GitHub
dot log             # 提交历史

dota .config/foo    # dot add 的简写（路径相对于 $HOME，可带前导 ./）

# 更新包列表
bash ~/.config/dotfiles/update-pkglist.sh
```

## 备份/回滚

```bash
# 打备份标签（不 push 也可以，本地回滚用）
dot tag backup-$(date +%F)

# 万一搞砸了，回滚
dot reset --hard backup-2026-07-19
```

## 设计原则

1. **配置文件优先，包列表辅助**：配置由 git 直接 checkout，包列表只解决"装什么"
2. **缓存不入库**：补全缓存、布局缓存、fisher 状态等自动生成物不跟踪，换机器自动重生成
3. **新机器零摩擦**：`setup.sh` 一行命令完成初始化，冲突文件自动备份
4. **不依赖第三方工具**：纯 git + bash，不需要 chezmoi/yadm/stow
