# lss 的 Arch dotfiles

基于 GNU Stow + 普通 git 仓库的现代 dotfiles 管理方案。

## 迁移说明

> 旧方案使用 bare git repo（`~/.cfg` 作为 GIT_DIR，`$HOME` 作为 worktree）。
> 新方案改为 `~/dotfiles` 普通 git 仓库 + GNU Stow 部署软链。
> 如果你还在用旧方案，参考 [HOW.md](HOW.md) 的迁移章节。

## 主要特性

- **GNU Stow 部署**: `~/dotfiles/home/` 作为 stow 包，`stow -d ~/dotfiles -t $HOME home` 一键部署软链
- **普通 git 仓库**: `~/dotfiles` 就是标准 git 仓库，GUI 工具 / `cd ~/dotfiles && git log` 直接可用
- **安全自动提交**: systemd timer 默认只提交配置源文件到本地，不自动 push；动态生成物和文档需人工提交
- **黑名单策略**: `.gitignore` 默认跟踪所有文件，黑名单排除敏感/缓存文件
- **新机器一键恢复**: `setup.sh` 完成 clone + stow 部署，`bootstrap.sh` 装依赖包
- **AUR helper 引导**: `bootstrap.sh` 支持 `--aur-helper auto|paru|yay`，默认 paru 优先、yay fallback
- **Dry-run 预演**: `setup.sh` / `bootstrap.sh` / `uninstall.sh` 都支持 `--dry-run`
- **反向卸载**: `uninstall.sh` 停止 user units + stow -D 撤销软链；默认保留仓库，`--remove-repo` 才删除仓库
- **CI 静态检查**: `.github/workflows/lint.yml` 对所有 .sh 跑 shellcheck + bash -n
- **包列表分层**: `packages/*.generated.txt` 保存当前机器快照，`packages/*.txt` 保存手工 profile，根目录包列表保留兼容软链
- **生成文件不跟踪**: 工具生成的 Fish completions、zcompdump、Matugen 主题和 cached_layouts 不进仓库；手写补全源文件仍受 Git 管理

## 仓库布局

```
~/dotfiles/                           # 普通 git 仓库根目录
├── README.md                         # 主文档（本文件）
├── HOW.md                            # 详细使用手册
├── autocommit.md                     # 自动提交方案设计文档
├── setup.sh                          # 新机器一键初始化（支持 --dry-run）
├── bootstrap.sh                      # 装包脚本（支持 --dry-run，含 AUR helper 引导）
├── uninstall.sh                      # 反向卸载（支持 --dry-run / --force / --remove-repo）
├── auto-commit.sh                    # 定时把工作区变动提交到本地（默认不 push）
├── update-pkglist.sh                 # 重新生成包列表
├── packages/                         # 生成包列表 + 手工安装 profile
│   ├── pkglist.generated.txt          # 当前机器原生包快照
│   ├── foreign-pkglist.generated.txt  # 当前机器 AUR 包快照
│   ├── core.txt / niri.txt / desktop.txt / laptop.txt / nvidia.txt
│   └── aur/                           # AUR 手工 profile
├── pkglist.txt                        # 兼容软链，指向 packages/*.generated.txt
├── foreign-pkglist.txt                # 兼容软链，指向 packages/*.generated.txt
├── .gitignore                        # 黑名单策略 gitignore
├── .github/
│   └── workflows/
│       └── lint.yml                  # CI: shellcheck + bash -n 静态检查
└── home/                             # GNU Stow 包（镜像 $HOME 结构）
    ├── .zshenv                       # → stow 后 $HOME/.zshenv 软链指向这里
    └── .config/
        ├── zsh/                      # zsh 配置（ZDOTDIR）
        ├── fish/                     # fish 配置（备用 shell）
        ├── bash/                     # bash 配置（兜底）
        ├── environment.d/            # systemd 环境变量
        ├── niri/                     # Niri 窗口管理器
        ├── waybar/                   # 状态栏
        ├── mako/                     # 通知
        ├── fuzzel/                   # 应用启动器
        ├── swaylock/                 # 锁屏
        ├── swayosd/                  # 音量/亮度 OSD
        ├── waypaper/                 # 壁纸
        ├── nvim/                     # Neovim (LazyVim)
        ├── vim/                      # Vim
        ├── kitty/                    # Kitty 终端
        ├── ghostty/                  # Ghostty 终端
        ├── yazi/                     # 文件管理器（TUI）
        ├── fastfetch/                # 系统信息
        ├── btop/                     # 任务管理器
        ├── cava/                     # 音频频谱可视化
        ├── matugen/                  # Material You 主题生成
        ├── fcitx5/                   # 中文输入法
        ├── fontconfig/               # 字体配置
        ├── gtk-3.0/                  # GTK3 主题
        ├── gtk-4.0/                  # GTK4 主题
        ├── starship.toml             # 跨 shell 提示符主题
        ├── scripts/                  # 自定义脚本
        └── systemd/user/             # dotfiles-autocommit.{service,timer}
```

> 管理脚本和文档（setup.sh / bootstrap.sh / README.md / HOW.md 等）位于仓库根目录，
> 不在 `home/` stow 包内。`home/` 只包含需要部署到 `$HOME` 的用户配置文件。

> `~/.config/mpv/` 是独立 git 仓库，有自己的 `.git` / `.gitignore`，不纳入 dotfiles，
> 重装时单独 clone。

## 快速开始

### 在新机器上恢复

```bash
# 0. 可选: 先预演看会做什么（不实际执行）
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/setup.sh) --dry-run

# 1. clone + stow 部署（自动安装 stow、clone 仓库、创建软链）
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/setup.sh)

# 2. 装包（默认安装当前机器 generated lists）
bash ~/dotfiles/bootstrap.sh

# 或选择额外的手工 profile
bash ~/dotfiles/bootstrap.sh --profile core,niri,desktop

# 指定 AUR helper；默认策略是 paru，失败后 fallback 到 yay
bash ~/dotfiles/bootstrap.sh --aur-helper paru

# 3. 重新加载 shell
exec zsh

# 4. （可选）启用 systemd user units
# 启用全部仓库 unit:
bash ~/dotfiles/setup.sh --enable-units
# 或只启用自动提交:
# bash ~/dotfiles/setup.sh --enable-units=dotfiles-autocommit.timer
# dotfiles-autocommit 默认只创建本地 commit，不会自动 push

# 5. 开启 linger（让 timer 在未登录时也能跑）
sudo loginctl enable-linger $USER
```

详见 [HOW.md](HOW.md)。

### 日常使用

```bash
# 在 ~/dotfiles 里用普通 git 操作
cd ~/dotfiles
git status          # 看哪些文件有变动
git diff            # 看具体改了什么
git add home/.config/foo  # 跟踪新文件
git commit -m "xxx" # 提交
git push            # 推到 GitHub
git log             # 提交历史

# 或者用 dot() 便捷函数（在 ~/.config/zsh/aliases.zsh 里定义）
dot status          # 等同于 git -C ~/dotfiles status
dot diff
dot add home/.config/foo
dot commit -m "xxx"
dot push

dota home/.config/foo  # 等同于 dot add -f（强制添加）

# 便捷别名
dots                # dot status
dotd                # dot diff
dotl                # dot log --oneline -10
dotp                # dot push

# 手动确认并推送自动生成的本地 commit
bash ~/dotfiles/auto-commit.sh --push

# 检查依赖、Stow 链接、生成文件和 systemd 状态
bash ~/.config/scripts/dot-doctor.sh

# 更新当前机器的 generated 包列表（不会覆盖手工 profile）
bash ~/dotfiles/update-pkglist.sh
```

## 备份/回滚

```bash
# 打备份标签（不 push 也可以，本地回滚用）
dot tag backup-$(date +%F)

# 万一搞砸了，回滚
dot reset --hard backup-2026-07-19
```

## 设计原则

1. **配置文件优先，包列表辅助**：配置由 stow 部署软链，包列表只解决"装什么"
2. **缓存不入库**：补全缓存、布局缓存、fisher 状态等自动生成物不跟踪，换机器自动重生成
3. **新机器零摩擦**：`setup.sh` 一行命令完成初始化，stow 自动处理软链
4. **普通 git 仓库**：`~/dotfiles` 是标准 git 仓库，GUI 工具直接可用，无需特殊环境变量
5. **可预演可回滚**：所有写操作脚本支持 `--dry-run`，`uninstall.sh` 提供反向卸载
6. **脚本有 CI 兜底**：push / PR 自动跑 shellcheck + bash -n，低级错误当场拦下
7. **AUR helper 引导**：`bootstrap.sh` 检测到没有 paru/yay 时自动构建一个，不再需要手动预装