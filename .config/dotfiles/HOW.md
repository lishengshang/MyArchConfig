# HOW - 使用手册

## 新机器恢复流程

### 完整流程（新装 Arch 后）

```bash
# 1. 安装基础工具（如果还没有）
sudo pacman -S git zsh

# 2. clone + 初始化 dotfiles
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/.config/dotfiles/setup.sh)

# 3. 重新加载 shell 让 dot/dota 别名生效
exec zsh

# 4. 安装所有软件包（pacman + AUR）
bash ~/.config/dotfiles/bootstrap.sh

# 5. 验证
dot status      # 应该是 clean
dot log -5      # 看最近的提交
```

`setup.sh` 会:
- 把裸仓库 clone 到 `~/.cfg`
- 把工作区 checkout 到 `$HOME`
- 如果本地已有同名文件且内容不同，会备份到 `~/.dotfiles-backup-*`
- 设置 `status.showUntrackedFiles=no`，避免 status 列出整个家目录

### 替代流程（手动 clone）

如果你想先看一眼再执行:

```bash
git clone --bare https://github.com/lishengshang/MyArchConfig.git ~/.cfg
GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME git checkout -f
GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME git config --local status.showUntrackedFiles no
exec zsh
```

## 日常操作

```bash
# 查看状态
dot status              # 已跟踪文件的变动
dot status -u           # 连未跟踪的一起看

# 提交变更
dot diff                # 看 diff
dot add .config/foo     # 跟踪新文件（要先白名单）
dota .config/foo        # 同上的简写（路径相对于 $HOME，可带前导 ./）
dot commit -m "msg"
dot push

# 看历史
dot log
dot log --oneline -10
dot show HEAD           # 看最新提交的内容

# 分支管理
dot branch
dot checkout -b feature/x
```

## 添加新配置

### 1. 单个文件

```bash
# 比如要跟踪 ~/.config/foo/config.toml
# 先在 ~/.gitignore 的白名单区加一行:
#     !.config/foo/
# 然后跟踪:
dota .config/foo/config.toml
dot commit -m "add foo config"
dot push
```

### 2. 整个目录

```bash
# 比如要跟踪 ~/.config/bar/ 整个目录
# 1) 编辑 ~/.gitignore，加白名单:
#     !.config/bar/
# 2) 跟踪
dota .config/bar
dot commit -m "add bar config"
dot push
```

`dota` 是 `dot add` 的简写，路径相对于 `$HOME`。它会检查文件存在性，跳过不存在的。

## 更新包列表

装了新软件后，更新包列表:

```bash
bash ~/.config/dotfiles/update-pkglist.sh

# 提交
dot add .config/dotfiles/pkglist.txt .config/dotfiles/foreign-pkglist.txt
dot commit -m "update pkglist: add foo"
dot push
```

可选: 设置 systemd user timer 自动更新（参考 `update-pkglist.sh` 文件头注释）。

## 备份 / 回滚

### 打标签（轻量备份）

```bash
# 大改动前打标签
dot tag pre-something-$(date +%F)
dot push --tags    # 推到 GitHub

# 万一搞砸了
dot reset --hard pre-something-2026-07-19
```

### stash 临时保存

```bash
# 中途要切到别的事，临时保存当前未提交的改动
dot stash
dot stash pop       # 恢复
```

## 缓存文件说明

以下文件**故意不跟踪**，换机器会自动重新生成:

| 文件 | 说明 | 重新生成方式 |
|---|---|---|
| `.config/zsh/.zcompdump*` | zsh 补全缓存 | 启动 zsh 时自动 |
| `.config/fish/completions/*.fish` | fish 补全（fisher/工具自动生成） | `fisher update` 或工具首次运行 |
| `.config/fish/fish_variables` | fisher 状态变量 | `fisher update` 时根据 `fish_plugins` 重新生成 |
| `.config/fcitx5/conf/cached_layouts` | fcitx5 键盘布局缓存 | fcitx5 启动时扫描 |
| `.config/fcitx5/cache/` | fcitx5 其他缓存 | fcitx5 启动时 |
| `.config/mpv/` | mpv 是独立 git 仓库（25 commit，有自己的 .gitignore） | 单独 clone mpv 仓库 |

如果你发现某个文件被错误跟踪了:

```bash
dot rm --cached .config/path/to/file
# 然后在 ~/.gitignore 的黑名单区加一条
dot add .gitignore
dot commit -m "untrack cache file"
```

## 多机器差异（未来需求）

目前不支持多机器差异。如果以后有需要:

- **简单方案**: 用分支 `dot checkout laptop` / `dot checkout desktop`
- **中等方案**: 迁移到 yadm，它支持 `##hostname.laptop` 这样的差异文件
- **重型方案**: 迁移到 chezmoi，支持模板、加密、机器感知

## 故障排查

### `dot status` 列出整个家目录

```bash
dot config status.showUntrackedFiles no
```

### `dot` 命令找不到

确认 `~/.config/zsh/aliases.zsh` 里有 `dot()` 函数定义，且 zsh 加载了别名文件。

### checkout 冲突

```bash
# 强制覆盖本地（会丢失未跟踪文件！）
GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME git checkout -f
```

或者手动备份冲突文件后重试。

### 推送被拒（远程有新提交）

```bash
dot pull --rebase
dot push
```
