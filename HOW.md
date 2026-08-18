# HOW - 使用手册

## 新机器恢复流程

### 完整流程（新装 Arch 后）

```bash
# 1. 安装基础工具（如果还没有）
sudo pacman -S git zsh

# 2. clone + stow 部署 dotfiles
bash <(curl -fsSL https://raw.githubusercontent.com/lishengshang/MyArchConfig/main/setup.sh)

# 3. 重新加载 shell 让 dot/dota 别名生效
exec zsh

# 4. 安装当前机器的 generated 软件包（pacman + AUR）
bash ~/dotfiles/bootstrap.sh

# 可选：额外安装手工 profile
bash ~/dotfiles/bootstrap.sh --profile core,niri,desktop

# 指定 AUR helper（auto / paru / yay）
bash ~/dotfiles/bootstrap.sh --aur-helper paru

# 5. （可选）启用 systemd user units
# 启用全部仓库 unit:
bash ~/dotfiles/setup.sh --enable-units
# 或只启用自动提交:
# bash ~/dotfiles/setup.sh --enable-units=dotfiles-autocommit.timer

# 6. 开启 linger（让 timer 在未登录时也能跑）
sudo loginctl enable-linger $USER

# 7. 验证
dot status      # 应该是 clean
dot log -5      # 看最近的提交
```

`setup.sh` 会:
- 检查并安装 `stow`（如果没有）
- 把仓库 clone 到 `~/dotfiles`
- 用 `stow -d ~/dotfiles -t $HOME home` 在 `$HOME` 下创建软链
- 如果 `$HOME` 下已有同名文件（非软链），stow 会报冲突，需手动处理
- 重生成 matugen 主题产物（失败不致命）

### 预演模式（先看会做什么）

新机器上想先看一眼再执行，或老机器上想验证脚本行为：

```bash
# setup.sh 预演: 显示会 clone 哪里、stow 部署什么
bash ~/dotfiles/setup.sh --dry-run

# bootstrap.sh 预演: 显示 generated 包和 profile 会装什么，不实际安装
bash ~/dotfiles/bootstrap.sh --dry-run --profile core,niri --aur-helper auto
```

`--dry-run` 不做任何写操作，可以放心跑。

### 替代流程（手动 clone + stow）

如果你想先看一眼再执行:

```bash
# 1. 安装 stow
sudo pacman -S stow

# 2. clone 仓库
git clone https://github.com/lishengshang/MyArchConfig.git ~/dotfiles

# 3. stow 部署
stow -d ~/dotfiles -t "$HOME" home

# 4. 重新加载 shell
exec zsh
```

## 日常操作

```bash
# 查看状态
dot status              # 已跟踪文件的变动
dot status -u           # 连未跟踪的一起看

# 提交变更
dot diff                # 看 diff
dot add home/.config/foo  # 跟踪新文件
dota home/.config/foo     # 同上的简写（dot add -f）
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

也可以直接 `cd ~/dotfiles` 后用普通 git 命令，效果一样。

## 添加新配置

### 1. 单个文件

```bash
# 比如要跟踪 ~/.config/foo/config.toml
# 1) 把文件放到 ~/dotfiles/home/.config/foo/config.toml
# 2) 如果是新目录，在 ~/dotfiles/home/.config/foo/ 下创建文件
# 3) stow 会自动创建软链（如果之前没 stow 过这个路径，需要重新 stow）
# 4) 提交
dot add home/.config/foo/config.toml
dot commit -m "add foo config"
dot push
```

### 2. 整个目录

```bash
# 比如要跟踪 ~/.config/bar/ 整个目录
# 1) 把目录复制到 ~/dotfiles/home/.config/bar/
# 2) 重新 stow（或用 --adopt 接管已有文件）
stow -d ~/dotfiles -t "$HOME" --adopt home
# 3) 提交
dot add home/.config/bar
dot commit -m "add bar config"
dot push
```

### 3. 用 stow --adopt 接管已有文件

如果 `$HOME` 下已有同名文件，stow 会报冲突。用 `--adopt` 让 stow 接管：

```bash
# stow --adopt 会把 $HOME 下的冲突文件移入 ~/dotfiles/home/，然后创建软链
stow -d ~/dotfiles -t "$HOME" --adopt home

# 然后检查 diff 确认内容正确
dot diff
dot commit -m "adopt existing config files"
dot push
```

## 更新包列表

装了新软件后，更新当前机器的 generated 包列表（不会覆盖手工 profile）:

```bash
bash ~/dotfiles/update-pkglist.sh

# 提交
git -C ~/dotfiles add packages pkglist.txt foreign-pkglist.txt
git -C ~/dotfiles commit -m "update pkglist: add foo"
git -C ~/dotfiles push
```

可选: 设置 systemd user timer 自动更新（参考 `update-pkglist.sh` 文件头注释）。

## 备份 / 回滚

### 自动备份（systemd user timer）

每 3 天凌晨 03:00 自动检测变更并创建本地 commit，不会自动 push 到 GitHub。错过的时间（关机/休眠）开机后补跑。需要同步远程时手动执行 `bash ~/dotfiles/auto-commit.sh --push`。

完整指南（工作原理 / 查看状态 / 修改频率 / 故障排查 / 安全说明）见 **[autocommit.md](autocommit.md)**。

常用命令速查:

```bash
# 查看 timer 状态 + 下次触发时间
systemctl --user list-timers dotfiles-autocommit.*

# 查看自动提交日志
journalctl --user -u dotfiles-autocommit.service -n 50

# 手动触发一次（只创建本地 commit，不 push）
systemctl --user start dotfiles-autocommit.service

# 手动确认并同步远程（pull --rebase + push）
bash ~/dotfiles/auto-commit.sh --push

# 暂停 / 恢复
systemctl --user stop dotfiles-autocommit.timer
systemctl --user start dotfiles-autocommit.timer
```

**必做**: 开启 linger 让 timer 在未登录时也能跑（一次性命令）:
```bash
sudo loginctl enable-linger $USER
```

### 手动备份（重要改动前推荐）

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
| `.config/fish/completions/*.fish` | 手写 Fish 补全源文件 | 随仓库恢复 |
| `.local/share/fish/generated-completions/*.fish` | 工具运行时生成的补全 | `fish-update-completions --force` |
| `.config/fish/fish_variables` | Fish universal 变量 | Fish 自己重新生成 |
| `.config/fcitx5/conf/cached_layouts` | fcitx5 键盘布局缓存 | fcitx5 启动时扫描 |
| `.config/fcitx5/cache/` | fcitx5 其他缓存 | fcitx5 启动时 |
| `.config/mpv/` | mpv 是独立 git 仓库 | 单独 clone mpv 仓库 |

如果你发现某个文件被错误跟踪了:

```bash
dot rm --cached home/.config/path/to/file
# 然后在 ~/dotfiles/.gitignore 的黑名单区加一条
dot add .gitignore
dot commit -m "untrack cache file"
```

## 多机器差异（未来需求）

目前不支持多机器差异。如果以后有需要:

- **简单方案**: 用分支 `dot checkout laptop` / `dot checkout desktop`
- **中等方案**: 迁移到 yadm，它支持 `##hostname.laptop` 这样的差异文件
- **重型方案**: 迁移到 chezmoi，支持模板、加密、机器感知

## 故障排查

### 一键健康检查

```bash
bash ~/.config/scripts/dot-doctor.sh
```

它会检查 Git 工作区、核心命令、可选依赖、Stow 链接、生成文件忽略规则、Fish 运行时补全、systemd user units 和 Niri 配置。

### stow 部署冲突

```bash
# stow 报冲突时，查看哪些文件冲突
stow -d ~/dotfiles -t "$HOME" -n home  # -n = dry-run，只报告不执行

# 方案 1: 备份冲突文件后重新 stow
mv ~/.config/conflict-file ~/.config/conflict-file.bak
stow -d ~/dotfiles -t "$HOME" home

# 方案 2: 用 --adopt 让 stow 接管（原文件移入仓库）
stow -d ~/dotfiles -t "$HOME" --adopt home
```

### `dot` 命令找不到

确认 `~/.config/zsh/aliases.zsh` 里有 `dot()` 函数定义，且 zsh 加载了别名文件。

新方案中 `dot()` 定义为:
```zsh
dot() { git -C "$HOME/dotfiles" "$@"; }
```

### 推送被拒（远程有新提交）

```bash
dot pull --rebase
dot push
```

### 软链断裂

如果 `$HOME` 下的软链指向不存在的文件（比如手动移动了 `~/dotfiles`）:

```bash
# 撤销旧软链
stow -d ~/dotfiles -t "$HOME" -D home

# 重新部署
stow -d ~/dotfiles -t "$HOME" home
```

## 卸载 dotfiles

想换工具、或清理 dotfiles 痕迹时用 `uninstall.sh`。

### 做什么 / 不做什么

| 动作 | 是否执行 |
|---|---|
| 停止并禁用仓库管理的 systemd user units | ✅ 会做 |
| `stow -D` 撤销 home/ 包的软链 | ✅ 会做 |
| 默认删除仓库目录 `~/dotfiles/` | ❌ 不做 |
| 使用 `--remove-repo` 删除仓库目录 | ✅ 明确指定后才做 |
| 删除 `$HOME` 下被 stow 部署的配置文件内容 | ❌ 不做（默认保留在 `~/dotfiles/home/`） |
| 删除 systemd user unit 文件 | ✅ 随 `stow -D` 撤销软链，不删除仓库中的源文件 |

### 用法

```bash
# 预演（看会做什么，不执行）
bash ~/dotfiles/uninstall.sh --dry-run

# 默认（交互确认）
bash ~/dotfiles/uninstall.sh

# 跳过确认（默认仍然保留仓库）
bash ~/dotfiles/uninstall.sh --force

# 明确删除仓库及其中保存的配置真实内容（会再次建议确认）
bash ~/dotfiles/uninstall.sh --remove-repo

# 无交互删除仓库（高风险，仅在确认备份后使用）
bash ~/dotfiles/uninstall.sh --remove-repo --force

# 帮助
bash ~/dotfiles/uninstall.sh --help
```

### 彻底清理（手动）

卸载脚本保留的文件，想彻底清掉：

```bash
rm -f ~/.config/systemd/user/dotfiles-autocommit.{service,timer}
systemctl --user daemon-reload
```

## 从旧方案迁移（bare repo → stow）

如果你还在用旧的 bare repo 方案（`~/.cfg` + GIT_DIR），迁移步骤:

```bash
# 1. clone 新仓库
git clone https://github.com/lishengshang/MyArchConfig.git ~/dotfiles

# 2. 撤销旧方案的软链（如果有）
# 旧方案没有软链，是直接 checkout 到 $HOME，所以这步跳过

# 3. stow 部署（--adopt 接管 $HOME 下已有的配置文件）
stow -d ~/dotfiles -t "$HOME" --adopt home

# 4. 检查 diff 确认内容正确
cd ~/dotfiles
git diff    # --adopt 移入的文件应该和远程一致

# 5. 如果一切正常，删除旧的 bare repo
rm -rf ~/.cfg

# 6. 重新加载 shell
exec zsh
```

> ⚠️ 迁移前请先备份！`~/.cfg` 删除后旧方案的历史就没了（但新仓库有完整 git 历史）。