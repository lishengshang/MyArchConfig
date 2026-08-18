# 自动备份指南

dotfiles 配了 systemd user timer，定期自动检测变更并创建本地 commit。timer 默认不会 push 到 GitHub；确认无误后手动执行 `bash ~/dotfiles/auto-commit.sh --push`。

## 工作原理

```
触发（每 3 天凌晨 03:00）
  ↓
auto-commit.sh
  ↓
cd ~/dotfiles && git status --porcelain
  ↓
工作区干净? ──是──> 静默退出（journal 一行）
   │
   否
   ↓
生成 commit message（时间戳 + 改动文件列表）
  ↓
筛选并暂存配置源文件   ← home/ + 根目录 *.sh；排除补全、主题、generated 和 VS Code 动态颜色
  ↓
git commit
  ↓
默认结束（只保留本地 commit，不访问远程）
  ↓
手动运行 auto-commit.sh --push?
   ├─否──> 完成
   └─是──> git pull --rebase → 冲突时停止并保留本地 commit → git push
```

## 当前配置

| 项 | 值 |
|---|---|
| 频率 | 每 3 天一次 |
| 触发时间 | 凌晨 03:00 |
| 触发日期 | 每月 1/4/7/10/13/16/19/22/25/28 号 |
| 补跑策略 | 关机错过的时段，开机后补跑（`Persistent=true`） |
| 重复触发 | 错过多次只跑一次（不堆积） |
| linger | 需手动开启（见下） |

## 文件清单

| 文件 | 作用 |
|---|---|
| `~/dotfiles/auto-commit.sh` | 核心脚本：检测变更 → 本地 commit；`--push` 才同步远程 |
| `~/.config/systemd/user/dotfiles-autocommit.service` | systemd service 定义 |
| `~/.config/systemd/user/dotfiles-autocommit.timer` | systemd timer 定义（频率在此改） |

> 注意: service 和 timer 文件通过 stow 部署到 `~/.config/systemd/user/`，
> 实际文件在 `~/dotfiles/home/.config/systemd/user/` 里。

## 必做：开启 linger

让 timer 在用户未登录时（凌晨机器开着但没登录）也能跑。**一次性命令：**

```bash
sudo loginctl enable-linger $USER
```

验证：

```bash
loginctl show-user $USER | grep Linger
# 应输出 Linger=yes
```

不开 linger 的后果：关机时段定时器不跑、开机后也不补跑（只在登录会话期间生效）。

## 日常操作

### 查看 timer 状态

```bash
# timer 当前状态 + 下次触发时间
systemctl --user status dotfiles-autocommit.timer

# 列出下次触发时间
systemctl --user list-timers dotfiles-autocommit.*
```

### 查看自动提交日志

```bash
# 最近 50 行
journalctl --user -u dotfiles-autocommit.service -n 50

# 实时跟踪
journalctl --user -u dotfiles-autocommit.service -f

# 只看今天的
journalctl --user -u dotfiles-autocommit.service --since today
```

### 手动触发一次

不想等到下次定时，立刻创建本地 commit：

```bash
# 方式 1：通过 systemd（推荐，日志走 journal）
systemctl --user start dotfiles-autocommit.service

# 方式 2：直接跑脚本（只创建本地 commit，不 push）
bash ~/dotfiles/auto-commit.sh

# 手动确认后同步远程（pull --rebase + push）
bash ~/dotfiles/auto-commit.sh --push
```

### 暂停 / 恢复

```bash
# 临时暂停（重启机器后还是 enabled 状态，只是当前停了）
systemctl --user stop dotfiles-autocommit.timer

# 恢复
systemctl --user start dotfiles-autocommit.timer
```

### 永久关闭 / 重新启用

```bash
# 永久关闭（开机不再启动）
systemctl --user disable --now dotfiles-autocommit.timer

# 重新启用
systemctl --user enable --now dotfiles-autocommit.timer
```

## 修改频率

编辑 `~/.config/systemd/user/dotfiles-autocommit.timer`（stow 软链指向 `~/dotfiles/home/.config/systemd/user/dotfiles-autocommit.timer`），改 `OnCalendar=` 行：

```ini
# 常用频率参考:
OnCalendar=*-*-* 03:00:00           # 每天 3 点
OnCalendar=*-*-1/3 03:00:00        # 每 3 天（当前）
OnCalendar=*-*-1/7 03:00:00         # 每周一次（每月 1/8/15/22 号）
OnCalendar=weekly                  # 每周
OnCalendar=*-*-* *:00:00           # 每小时整点
OnCalendar=*-*-* *:00,30:00        # 每 30 分钟
OnCalendar=hourly                  # 每小时
```

改完必须 reload + restart：

```bash
systemctl --user daemon-reload
systemctl --user restart dotfiles-autocommit.timer
# 验证下次触发时间
systemctl --user list-timers dotfiles-autocommit.*
```

可以用 `systemd-analyze calendar` 预测下次触发时间，不用真的等：

```bash
systemd-analyze calendar "*-*-1/3 03:00:00"
```

## 自动 commit 长什么样

```bash
$ dot log --oneline -3
abc1234 auto: 2026-07-22 03:00:01
def5678 auto: 2026-07-19 03:00:02
9abcdef 手动 commit message
```

完整 message 长这样：

```
auto: 2026-07-22 03:00:01

改动文件 (3): home/.config/niri/config.kdl,home/.config/zsh/aliases.zsh,home/.config/waybar/modules.jsonc
- 新增/未跟踪: 0
- 修改: 3
- 删除: 0

(由 systemd timer dotfiles-autocommit.timer 自动提交)
```

## 故障排查

### timer 没跑

```bash
# 1. 检查 timer 是否 enabled + active
systemctl --user status dotfiles-autocommit.timer

# 2. 检查下次触发时间
systemctl --user list-timers dotfiles-autocommit.*

# 3. 检查 linger（没开的话关机时段不会补跑）
loginctl show-user $USER | grep Linger

# 4. 手动跑一次看错误
bash ~/dotfiles/auto-commit.sh
```

### service 失败

```bash
# 查看最近一次失败的完整日志
journalctl --user -u dotfiles-autocommit.service -n 50
```

常见原因：

| 错误信息 | 原因 | 解决 |
|---|---|---|
| `pull --rebase 失败` | 使用 `--push` 时远程有冲突 commit | `dot status` 看，`dot rebase --abort` 放弃 或 `--continue` 解决 |
| `push 失败` | 使用 `--push` 时网络问题 / gh 凭证失效 | `gh auth status` 检查 |
| `permission denied` | 脚本没执行权限 | `chmod +x ~/dotfiles/auto-commit.sh` |

### rebase 冲突处理

使用 `auto-commit.sh --push` 检测到冲突会停止 push，本地保留 commit。你需要手动处理：

```bash
# 看当前状态
dot status

# 如果是 auto-commit 留下的 rebase 中断
dot rebase --abort    # 放弃 auto commit，回到远程版本
# 或
dot rebase --continue  # 解决冲突后继续

# 然后 push
dot push
```

## 安全说明

### 自动提交范围

自动提交不是对整个仓库执行无条件的 `git add -A`，而是只处理：

- `home/` 下的配置源文件；
- 仓库根目录下的 `*.sh` 维护脚本。

以下内容不会被自动提交，必须人工审查后提交：

- `~/.local/share/fish/generated-completions/`（仓库中的手写补全源仍可自动提交）；
- `fish_variables`；
- `home/.config/**/colors.*`；
- `home/.config/**/generated.*`；
- `35-pager-matugen.fish`；
- VS Code `settings.json` 动态颜色；
- README、HOW、包列表和 Agent 协作文档。

这不会取消 `.gitignore` 的作用。`.gitignore` 仍然是敏感文件的第二层防线：

```gitignore
# 敏感文件
.env
*.key
*.pem
credentials

# 敏感目录
.ssh/
.gnupg/

# 缓存 / 自动生成物
.netrwhist
*.wants/
```

即使 `home/` 下出现这些文件，也会被忽略。`$HOME` 下的其他文件（`.bash_history`、`.cache/` 等）不在仓库目录内，根本不会被 git 看到。

### 万一误推了敏感信息

```bash
# 1. 立即从远程删除最近一次 commit（保留本地）
dot push --force-with-lease origin HEAD~1:main

# 2. 立即去 GitHub 把 token/密钥撤销
#    （git push --force 只是删除引用，commit 内容仍可能在 GitHub 缓存里）

# 3. 如果是 GitHub Personal Access Token 泄露，去 Settings > Developer settings 撤销
```

## 在新机器上恢复

`setup.sh` 不会自动启用 timer。新机器恢复后手动启用：

```bash
# 1. 启用 timer
systemctl --user enable --now dotfiles-autocommit.timer

# 2. 开 linger
sudo loginctl enable-linger $USER

# 3. 验证
systemctl --user list-timers dotfiles-autocommit.*
```