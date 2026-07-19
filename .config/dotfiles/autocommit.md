# 自动备份指南

dotfiles 配了 systemd user timer，定期自动检测变更并 commit + push 到 GitHub。

## 工作原理

```
触发（每 3 天凌晨 03:00）
  ↓
auto-commit.sh
  ↓
dot status --porcelain
  ↓
工作区干净? ──是──> 静默退出（journal 一行）
   │
   否
   ↓
生成 commit message（时间戳 + 改动文件列表）
  ↓
dot add -A   ← .gitignore 兜底，缓存/敏感文件进不来
  ↓
dot commit
  ↓
dot pull --rebase   ← 处理多机器冲突
  ↓
冲突? ──有──> 放弃 push，本地保留 commit（你手动处理）
   │
   否
   ↓
dot push origin main
  ↓
完成
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
| `~/.config/dotfiles/auto-commit.sh` | 核心脚本：检测变更 → commit → push |
| `~/.config/systemd/user/dotfiles-autocommit.service` | systemd service 定义 |
| `~/.config/systemd/user/dotfiles-autocommit.timer` | systemd timer 定义（频率在此改） |

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

不想等到下次定时，立刻跑一次：

```bash
# 方式 1：通过 systemd（推荐，日志走 journal）
systemctl --user start dotfiles-autocommit.service

# 方式 2：直接跑脚本（日志直接输出到终端）
bash ~/.config/dotfiles/auto-commit.sh
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

编辑 `~/.config/systemd/user/dotfiles-autocommit.timer`，改 `OnCalendar=` 行：

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

改动文件 (3): .config/niri/config.kdl,.config/zsh/aliases.zsh,.config/waybar/colors.css
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
bash ~/.config/dotfiles/auto-commit.sh
```

### service 失败

```bash
# 查看最近一次失败的完整日志
journalctl --user -u dotfiles-autocommit.service -n 50
```

常见原因：

| 错误信息 | 原因 | 解决 |
|---|---|---|
| `pull --rebase 失败` | 远程有冲突 commit | `dot status` 看，`dot rebase --abort` 放弃 或 `--continue` 解决 |
| `push 失败` | 网络问题 / gh 凭证失效 | `gh auth status` 检查 |
| `permission denied` | 脚本没执行权限 | `chmod +x ~/.config/dotfiles/auto-commit.sh` |

### rebase 冲突处理

auto-commit 检测到冲突会放弃 push，本地保留 commit。你需要手动处理：

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

### 为什么 `dot add -A` 是安全的

`~/.gitignore` 用两层模式兜底：

```gitignore
/*                          # 默认忽略 $HOME 下所有文件
!.config/                   # 但进入 .config 目录
.config/*                   # .config 下默认也全忽略
!.config/foo/               # 只白名单指定目录
```

白名单外的所有文件（`.ssh/`、`.gnupg/`、`.bash_history`、`.cache/`、`.config/mpv/` 等）都进不来。`dot add -A` 只会加白名单内的变更。

### 敏感文件不会泄露

`~/.gitignore` 黑名单区明确排除：

```gitignore
.env
.env.*
*.pem
*.key
*.secret
credentials
.ssh/
.gnupg/
```

即使在白名单目录里出现这些文件，也会被忽略。

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
