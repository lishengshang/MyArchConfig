# lss 的 Arch dotfiles

基于 bare git repo 的现代 dotfiles 管理方案。

## 主要特性

- **裸仓库管理**: `~/.cfg` 作为 GIT_DIR，`$HOME` 作为 worktree，零额外依赖
- **白名单策略**: `~/.gitignore` 默认 `/*` 忽略一切，按需白名单配置目录
- **新机器一键恢复**: `setup.sh` 完成初始化，`bootstrap.sh` 装依赖包
- **Dry-run 预演**: `setup.sh` / `bootstrap.sh` / `uninstall.sh` 都支持 `--dry-run`，先看会做什么再决定
- **反向卸载**: `uninstall.sh` 停 timer + 删裸仓库，保留 $HOME 下配置文件
- **CI 静态检查**: `.github/workflows/lint.yml` 对所有 .sh 跑 shellcheck + bash -n
- **包列表自动生成**: `pkglist.txt` + `foreign-pkglist.txt` 记录已装软件
- **缓存文件不跟踪**: fish completions、zcompdump、cached_layouts 等自动生成物不进仓库

## 仓库布局

```
~/
├── .cfg/                          # 裸仓库内部文件（GIT_DIR，不要手动改）
├── .gitignore                     # dotfiles 仓库的 gitignore（白名单策略）
├── .zshenv                        # zsh 入口，把 ZDOTDIR 指向 ~/.config/zsh
├── README.md -> .config/dotfiles/README.md   # 软链到本文档
├── .config/
│   ├── dotfiles/                  # ← 你正在看的目录，受版本控制
│   │   ├── README.md              # 主文档（本文件）
│   │   ├── HOW.md                 # 详细使用手册
│   │   ├── setup.sh               # 新机器一键初始化（支持 --dry-run）
│   │   ├── bootstrap.sh           # 装包脚本（支持 --dry-run）
│   │   ├── uninstall.sh           # 反向卸载（支持 --dry-run / --force）
│   │   ├── update-pkglist.sh      # 重新生成包列表
│   │   ├── autocommit.md          # 自动提交方案设计文档
│   │   ├── auto-commit.sh         # 定时把工作区变动提交到 backup 分支
│   │   ├── pkglist.txt            # pacman 原生包列表（自动生成）
│   │   └── foreign-pkglist.txt     # AUR 包列表（自动生成）
│   │
│   ├── zsh/                       # zsh 配置（ZDOTDIR，详见其 README.md）
│   ├── fish/                      # fish 配置（备用 shell）
│   ├── bash/                      # bash 配置（兜底）
│   ├── environment.d/             # systemd 环境变量（XDG / EDITOR / PATH / FZF_*）
│   │
│   ├── niri/                      # Niri 窗口管理器
│   ├── waybar/                    # 状态栏
│   ├── mako/                      # 通知
│   ├── fuzzel/                    # 应用启动器
│   ├── swaylock/                  # 锁屏
│   ├── swayosd/                   # 音量 / 亮度 OSD
│   ├── waypaper/                  # 壁纸
│   │
│   ├── nvim/                      # Neovim (LazyVim)
│   ├── vim/                       # Vim
│   ├── kitty/                     # Kitty 终端
│   ├── ghostty/                   # Ghostty 终端
│   │
│   ├── yazi/                      # 文件管理器（TUI）
│   ├── fastfetch/                 # 系统信息
│   ├── btop/                      # 任务管理器
│   ├── cava/                      # 音频频谱可视化
│   ├── matugen/                   # Material You 主题生成
│   │
│   ├── fcitx5/                    # 中文输入法
│   ├── fontconfig/                # 字体配置
│   │
│   ├── gtk-3.0/                   # GTK3 主题
│   ├── gtk-4.0/                   # GTK4 主题
│   ├── starship.toml              # 跨 shell 提示符主题
│   │
│   ├── scripts/                   # 自定义脚本
│   └── systemd/user/              # dotfiles-autocommit.{service,timer}
└── .github/
    └── workflows/
        └── lint.yml               # CI: shellcheck + bash -n 静态检查
```

> `~/.config/mpv/` 是独立 git 仓库，有自己的 `.git` / `.gitignore`，不纳入 dotfiles，
> 重装时单独 clone。详见 `.gitignore` 中的注释。

## 快速开始

### 在新机器上恢复

```bash
# 0. 可选: 先预演看会做什么（不实际执行）
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/.config/dotfiles/setup.sh) --dry-run

# 1. clone + checkout（处理冲突文件备份）
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/.config/dotfiles/setup.sh)

# 2. 装包（可选，支持 --dry-run 预演）
bash ~/.config/dotfiles/bootstrap.sh

# 3. 重新加载 shell
exec zsh
```

详见 [HOW.md](.config/dotfiles/HOW.md)。

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
5. **可预演可回滚**：所有写操作脚本支持 `--dry-run`，`uninstall.sh` 提供反向卸载
6. **脚本有 CI 兜底**：push / PR 自动跑 shellcheck + bash -n，低级错误当场拦下
