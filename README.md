# lss 的 Arch dotfiles

[![lint](https://github.com/lishengshang/MyArchConfig/actions/workflows/lint.yml/badge.svg)](https://github.com/lishengshang/MyArchConfig/actions/workflows/lint.yml)

基于 GNU Stow + 普通 git 仓库的 Arch Linux (Niri + Wayland) dotfiles。

> 历史说明：本仓库最初是 bare git repo（`~/.cfg` + `$HOME` worktree），2026-08 重构为
> `~/dotfiles` 普通仓库 + Stow 部署。旧方案迁移步骤见 [HOW.md](HOW.md) 末章。

## 文档导航

| 文档 | 内容 |
|---|---|
| [HOW.md](HOW.md) | 完整使用手册：恢复、日常操作、添加配置、备份回滚、故障排查、卸载 |
| [autocommit.md](autocommit.md) | 自动提交 timer 的设计文档 |
| [MAINTENANCE_PLAN.md](MAINTENANCE_PLAN.md) | 多 Agent 协作维护的任务登记与已知问题 |
| [AGENTS.md](AGENTS.md) | 多 Agent 协同规范（含 commit 信息规范） |
| [home/.config/fish/README.md](home/.config/fish/README.md) · [home/.config/zsh/README.md](home/.config/zsh/README.md) | 双 shell 配置的详细文档 |

## 主要特性

- **GNU Stow 部署**：`home/` 作为唯一 stow 包，`stow -d ~/dotfiles -t $HOME home` 一键软链
- **普通 git 仓库**：`cd ~/dotfiles && git log` / GUI 工具直接可用
- **双主力 shell**：zsh 与 fish 并列维护（有意设计）；bash 仅作登录兜底
- **安全自动提交**：systemd timer 只创建本地 commit 不自动 push；生成物与文档需人工提交
- **黑名单 gitignore**：默认跟踪所有文件，黑名单排除敏感/缓存/生成物
- **新机器一键恢复**：`setup.sh`（clone + stow）+ `bootstrap.sh`（装包，含 AUR helper 引导）
- **Dry-run 预演**：`setup.sh` / `bootstrap.sh` / `uninstall.sh` 均支持
- **反向卸载**：`uninstall.sh` 撤销软链并停用 units；默认保留仓库，`--remove-repo` 才删除
- **CI 静态检查**：shell（bash/zsh/fish + shellcheck）、Python、TOML、JSONC、
  systemd unit、niri KDL 校验 + Stow 临时 HOME 集成测试 + gitleaks 密钥扫描
- **包列表分层**：`packages/*.generated.txt` 为本机快照，`packages/*.txt` 为手工 profile

## 仓库布局

```
~/dotfiles/                            # 普通 git 仓库根
├── README.md / HOW.md                 # 文档（本文件为入口，HOW 为手册）
├── AGENTS.md / MAINTENANCE_PLAN.md    # 多 Agent 协作规范与任务登记
├── autocommit.md                      # 自动提交设计文档
├── setup.sh                           # 新机器初始化：clone + stow（--dry-run / --enable-units）
├── bootstrap.sh                       # 装包（--dry-run / --profile / --aur-helper）
├── uninstall.sh                       # 反向卸载（--dry-run / --force / --remove-repo）
├── auto-commit.sh                     # 定时本地提交（默认不 push，--push 显式同步）
├── update-pkglist.sh                  # 重新生成本机包快照
├── systemd-user-units.txt             # 仓库管理的 user unit 清单（setup/uninstall 共用）
├── packages/                          # 包列表
│   ├── *.generated.txt                #   本机快照（pacman / AUR）
│   ├── {core,niri,desktop,laptop,nvidia}.txt   #   手工 profile
│   └── aur/                           #   AUR 手工 profile
├── pkglist.txt / foreign-pkglist.txt  # 兼容软链 → packages/*.generated.txt
├── tests/
│   ├── stow/integration.sh            # Stow 临时 HOME 集成测试
│   ├── config/check_toml_jsonc.py     # TOML/JSONC 静态检查（本地/CI 共用）
│   └── zsh/                           # zsh smoke/bench 测试
├── .github/workflows/lint.yml         # CI：多语言静态检查 + gitleaks
└── home/                              # ★ GNU Stow 包（唯一，镜像 $HOME）
    ├── .zshenv / .bashrc / .bash_profile / .bash_logout   # shell 入口 wrapper
    ├── .gitconfig
    ├── .stow-local-ignore
    ├── .local/share/applications/     # clash:// 协议 handler 等手写 desktop 文件
    └── .config/
        ├── zsh/                       # zsh 配置（ZDOTDIR，模块化）
        ├── fish/                      # fish 配置（并列主力，含专属 README）
        ├── bash/                      # bash 兜底配置
        ├── niri/                      # Niri 合成器（config/binds/rule 分文件 + scripts/）
        ├── waybar/                    # 状态栏（三文件拆分 + scripts/）
        ├── fuzzel/ mako/              # 启动器 / 通知
        ├── systemd/user/              # 12 个 user unit（壁纸/主题/锁屏/剪贴板/自动提交等）
        ├── environment.d/             # systemd 用户会话环境变量
        ├── autostart/                 # XDG 自启动覆盖（niri 会话治理）
        ├── matugen/                   # Material You 主题引擎（config + 模板库）
        ├── atuin/                     # shell 历史搜索（Ctrl+R，zsh/fish 共用）
        ├── niri-clip/                 # 剪贴板守护的配置（二进制经 cargo install）
        ├── xdg-desktop-portal/        # portal 选择（截屏/录屏/文件选择器）
        ├── xdg-terminals.list         # xdg-terminal-exec 终端注册
        ├── kitty/ ghostty/            # 终端（kitty 主力，ghostty 备用）
        ├── nvim/                      # Neovim (LazyVim)
        ├── btop/ cava/                # 系统监视器 / 音频频谱
        ├── fcitx5/ fontconfig/        # 输入法 / 字体
        ├── gtk-3.0/ gtk-4.0/          # GTK 主题
        ├── starship/                  # 提示符 base.toml（colors 由 matugen 生成）
        ├── waypaper/                  # 壁纸选择器（backend=awww）
        ├── Code/User/                 # VS Code settings.base.json（运行时注入取色）
        ├── pacman/ mimeapps.list / user-dirs.dirs   # 系统级杂项
        └── scripts/                   # 跨组件自定义脚本（dot-doctor 等）
```

> 管理脚本与文档在仓库根目录，不进 `home/` stow 包。
> `~/.config/mpv/` 是独立 git 仓库（自带 `.git`），不纳入本仓库，重装时单独 clone。

## 快速开始（新机器恢复）

```bash
# 0. 预演看会做什么（不实际执行）
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/setup.sh) --dry-run

# 1. clone + stow 部署
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/setup.sh)

# 2. 装包（默认本机 generated 快照；或 --profile core,niri,desktop 选手工 profile）
bash ~/dotfiles/bootstrap.sh

# 3. 重载 shell 后启用 systemd user units（默认全部；可 =unit 名指定）
exec zsh
bash ~/dotfiles/setup.sh --enable-units

# 4. 开启 linger，让 timer 在未登录时也能跑
sudo loginctl enable-linger $USER
```

nirius/nirinit 等外部工具的安装逻辑、AUR helper 引导细节见 [HOW.md](HOW.md)。

## 日常操作速览

```bash
dot status && dot diff && dot log --oneline -10   # dot() = git -C ~/dotfiles
bash ~/.config/scripts/dot-doctor.sh              # 一键健康检查
bash ~/dotfiles/auto-commit.sh --push             # 手动同步远程
bash ~/dotfiles/update-pkglist.sh                 # 更新本机包快照
```

日常提交、添加新配置、备份回滚、故障排查的完整说明见 [HOW.md](HOW.md)。

## 备份/回滚

```bash
dot tag backup-$(date +%F)        # 打备份标签（本地回滚用）
dot reset --hard backup-2026-07-19   # 回滚到标签
```

自动提交 timer 的完整说明见 [autocommit.md](autocommit.md)。

## 设计原则

1. **配置文件优先，包列表辅助**：配置由 stow 部署软链，包列表只解决「装什么」
2. **源与生成物分离**：matugen 产物、补全缓存、fisher 状态等不入库，换机自动重生成
3. **新机器零摩擦**：`setup.sh` 一行完成初始化，所有写操作脚本支持 `--dry-run`
4. **普通 git 仓库**：无特殊环境变量，GUI 工具直接可用
5. **脚本有 CI 兜底**：push/PR 自动跑多语言静态检查与集成测试
6. **休眠配置保留注释态**：未安装软件的 matugen 模板等保留注释块，装软件后取消注释即启用
