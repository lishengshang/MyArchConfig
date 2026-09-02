# Dotfiles 维护计划

> 用于多个不同 Agent 平台协同维护。这里不假设 Agent 来自同一个平台、同一个会话或同一个工作目录。每个 Agent 只处理自己认领的任务，不要顺手修改无关配置。
>
> Git 和本文件是跨平台协作的事实来源。当前仓库在创建本计划时存在未提交修改，详见文末的“协作前置检查”。

## 使用约定

### 任务状态

- `[ ]` 未开始
- `[>]` 已认领，正在处理
- `[?]` 被阻塞，需要人工决定
- `~~[x] ...~~` 已完成（必须保留删除线，并补充 Agent、日期、验证结果）

认领任务时，在状态后注明平台和 Agent 标识，例如：

```markdown
- `[>]` P0-1 修复 CI 扫描范围 — Owner: Claude / ci-agent-01
```

完成任务时，不要删除任务记录；将整行改为：

```markdown
~~[x] 修复 ...~~ — Agent: 平台 / name, 日期: YYYY-MM-DD；验证: `command`
```

### Agent 协作规则

1. 开始前先执行 `git status --short`，确认工作区状态。
2. 不要覆盖、还原或提交其他 Agent/用户已有的修改。
3. 只修改当前任务所需的文件；发现跨任务问题时，记录到“发现但未处理”区域。
4. 完成后必须运行任务对应的验证命令。
5. 更新本文对应任务的状态，并写明平台、Agent 标识、修改文件、验证命令和剩余风险。
6. 不要执行 `git reset --hard`、`git clean -fd` 或批量删除未知文件。
7. 在自动提交机制未审查前，不要主动启用或触发 dotfiles 自动 push。
8. 不要把密钥、token、`.env`、机器私有数据加入仓库。
9. 不同平台的 Agent 不要同时修改同一组文件；发现范围重叠时，将任务标记为 `[?]` 并等待负责人分配。
10. 如果共享同一个工作目录，修改前后都检查 `git status --short` 和 `git diff --name-only`；不要假设未提交修改属于自己。
11. 如果使用独立 clone/分支，使用唯一任务 ID；合并和最终删除线状态由仓库负责人统一确认。

## 当前 P0 任务

### P0-1：修复 CI 扫描范围

~~[x] 修复 `.github/workflows/lint.yml` 中 `find . -maxdepth 1 ...` 导致只扫描仓库根目录的问题。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: 本地执行等价的多语言扫描通过
~~[x] Bash 脚本执行 `bash -n` 和 `shellcheck`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `shellcheck -S error`
~~[x] Fish 脚本执行 `fish -n`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `find home -name '*.fish' ... fish -n`
~~[x] Zsh 脚本执行 `zsh -n`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `find home tests -name '*.zsh' ... zsh -n`
~~[x] Python 脚本执行 `python3 -m py_compile`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `python3 -m py_compile home/.config/niri/scripts/niri-quick-switch-fuzzel.py`
~~[x] CI 应明确处理“扩展名为 `.sh` 但 shebang 是 Fish”的文件。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: shebang 分派检查

验收：CI 能检查 `home/.config/niri/scripts/`、`home/.config/scripts/`、`home/.config/waybar/scripts/`，而不是只有仓库根目录脚本。

### P0-2：修复截图菜单脚本语法

~~[x] 修复 `home/.config/waybar/scripts/power-screenshot.sh` 末尾缺失的 `done`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash -n home/.config/waybar/scripts/power-screenshot.sh`
~~[x] 删除错误的 `doney`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash -n home/.config/waybar/scripts/power-screenshot.sh`
~~[x] 验证：`bash -n home/.config/waybar/scripts/power-screenshot.sh`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；结果: 通过

### P0-3：修复安全卸载逻辑

~~[x] 修改 `uninstall.sh`：默认 `stow -D` 后保留 `~/dotfiles`，不要删除配置真实内容。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash uninstall.sh --dry-run`
~~[x] 增加显式 `--remove-repo` 选项，用户确认后才删除仓库。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash uninstall.sh --help`
~~[x] 删除仓库前提供明确的二次确认。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash -n uninstall.sh`、交互逻辑审查
~~[x] 统一停止/禁用仓库管理的所有 user units，而不仅是 `dotfiles-autocommit`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash uninstall.sh --dry-run`
~~[x] 同步修正 `README.md`、`HOW.md` 中的卸载说明。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `git diff --check`

验收：默认卸载后，配置内容仍可从仓库恢复；`--dry-run` 的输出与真实行为一致。

### P0-4：修复录屏 Waybar 入口

~~[x] 处理 `home/.config/waybar/modules.jsonc` 中不存在的 `shorin-screenrec-menu` 命令。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: 配置入口已指向仓库脚本
~~[x] 统一使用 `~/.config/waybar/scripts/screenrec toggle/stop`，或提供并纳入仓库的 wrapper。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `git diff -- home/.config/waybar/modules.jsonc`
- `[>]` 验证 `status-json`、`toggle`、`stop` 三个入口；当前环境未进行真实 Wayland 录屏测试。

### P0-5：移除 Wayland socket 硬编码

~~[x] 修改 `home/.config/systemd/user/awww-overview-daemon.service`，不要硬编码 `wayland-1`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `systemd-analyze verify`
~~[x] 使用 session 导入的 `WAYLAND_DISPLAY`，并等待图形会话就绪。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash -n`、`shellcheck -S error`、wrapper 选择当前 socket
- `[>]` 在不同 `wayland-0`/`wayland-1` 环境下验证服务启动；当前机器已有 awww overview daemon，实际启动测试命中“instance already running”。

### P0-6：整理 fnm 初始化

~~[x] 删除重复的 fnm 初始化，统一由 mise 负责 Node 版本。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: Fish/Zsh 语法检查、Zsh smoke tests
~~[x] 决定 Zsh 使用 `mise`，不再同时使用 fnm/mise/手写 PATH。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `home/.config/zsh/integrations.zsh`、`home/.config/fish/conf.d/50-tools.fish`
~~[x] 移除 `/home/mio` 和具体 Node 版本号等机器私有硬编码。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `rg -n -i 'fnm|node-versions' home`
~~[x] 审查并删除当前未跟踪文件 `home/.config/fish/conf.d/fnm.fish`。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；结果: 采用 mise 方案，不保留 fnm 文件

## P1 任务：可靠性和可迁移性

### P1-1：自动提交安全性

~~[x] 为 `auto-commit.sh` 增加 `flock`，防止 timer 与手动执行并发。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: 临时仓库执行
~~[x] 使用 exit code 判断 `pull`/`push` 成功，不要依赖 Git 输出文本 grep。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `shellcheck -S error auto-commit.sh`
~~[x] 改进包含空格、rename 的路径处理。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: 临时仓库测试包含空格路径
~~[x] 明确自动提交范围，自动处理 `home/` 配置源和根目录 `*.sh`，排除生成文件与文档。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: 临时仓库范围测试
~~[x] 默认关闭自动 push，改为显式 `auto-commit.sh --push`。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: 临时仓库确认默认无远程操作
~~[x] 为自动提交增加 GitHub Actions Gitleaks secret scanning。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: workflow 结构检查，CI 运行待 GitHub 验证

### P1-2：生成文件和 Git 忽略策略

~~[x] Fish 工具补全改为运行时生成；手写补全源文件继续入库。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `fish -n`、runtime completion generation、Fish completion path
~~[x] 处理 `fish_variables`、Matugen 生成的 `colors.*`、generated 配置等文件。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `.gitignore` 检查
~~[x] 验证 `git check-ignore` 与文档声明一致。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `git check-ignore -v`
~~[x] 避免动态主题每次变化都污染 Git 历史。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: Matugen/VS Code injector 静态和临时 HOME 测试

### P1-3：Bash XDG 入口

~~[x] 确保普通 Bash 会读取 `~/.config/bash/bashrc` 和 `bash_logout`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: Bash wrapper 和配置语法检查
~~[x] 增加 `home/.bashrc`、`home/.bash_logout`、`home/.bash_profile` wrapper。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash -n`
~~[x] 增加 Bash 配置重复 source 防护。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `DOTFILES_BASHRC_LOADED` guard
- `[ ]` 在未配置系统级 trampoline 的 Arch 环境验证。

### P1-4：硬件和主机差异

- `[?]` 用户选择 P1-4-D：暂时只维护当前机器，暂不进行 host overlay 抽象。
- `[ ]` 将 Niri 显示器、GPU、键盘背光、Wayland 环境等机器专属内容拆成 host overlay。
- `[ ]` 检查 `output.kdl`、sudoers 注释、测试脚本中的用户名和绝对路径。
- `[ ]` 为 laptop/desktop/NVIDIA 等场景建立独立配置或包 profile。

### P1-5：锁屏和休眠竞态

~~[x] 审查并区分 `lock-screen.sh` 的异步启动与等待启动行为。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `--help`、静态检查
~~[x] 让 `swayidle before-sleep` 和熄屏流程等待 hyprlock 建立。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `swayidle.sh` 命令审查
~~[x] 增加防止多个 hyprlock 实例竞态的 `flock`。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `shellcheck -S error`
~~[x] 加强锁屏就绪检查、动态颜色回退、等待模式竞态处理，并让所有锁屏入口等待 Hyprlock 建立。~~ — Agent: pi / secure-niri, 日期: 2026-08-20；验证: `bash -n`、`shellcheck -S error`、`niri validate`

### P1-6：Git 安全配置

~~[x] 审查 `home/.gitconfig` 中的 `safe.directory = *`。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；结果: 确认不需要全局信任
~~[x] 删除 `safe.directory = *`，恢复 Git 默认 ownership 安全检查。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `git status`、`git diff --check`
~~[x] 增加 gitleaks secret scanning CI。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `.github/workflows/lint.yml` 结构检查，实际扫描待 GitHub 运行

## P2 任务：依赖和长期维护

~~[x] 将剪贴板历史改为显式 opt-in，移除固定的 clipsync-git 依赖，并增加安全的启动/重启 wrapper。~~ — Agent: pi / secure-niri, 日期: 2026-08-20；验证: `bash -n`、默认关闭运行测试、Waybar 配置检查
~~[x] 修复 GTK tooltip 拼写、VS Code 包 provide 误判、随机壁纸并发竞态和 dot-doctor 的 Niri service 误报。~~ — Agent: pi / secure-niri, 日期: 2026-08-20；验证: `shellcheck -S error`、`dot-doctor.sh`、Matugen injector smoke test
~~[x] 将 nirius 纳入 Niri profile，并让 bootstrap 在缺少时安装 `nirinit` cargo 工具。~~ — Agent: pi / secure-niri, 日期: 2026-08-20；验证: `bash -n bootstrap.sh`、`bootstrap.sh --dry-run --profile niri`
~~[x] 增加不影响 KDE/Qt 的 GTK 定时主题服务，并用 Breeze/Breeze-Dark 做已安装主题的稳定方案。~~ — Agent: pi / theme-clipboard, 日期: 2026-08-20；验证: service/timer verify、07/18 时段模拟、GSettings 检查
~~[x] 增加支持置顶、删除确认和清空确认的 cliphist 自定义 TUI，固定状态只保存 cliphist ID。~~ — Agent: pi / theme-clipboard, 日期: 2026-08-20；验证: `bash -n`、`shellcheck -S error`、临时 cliphist 数据库删除测试
~~[x] 启用 Matugen Fcitx5 主题，并让 Fcitx5 ClassicUI 使用独立的 Matugen-Light/Matugen-Dark 主题。~~ — Agent: pi / theme-clipboard, 日期: 2026-08-20；验证: `matugen-update.sh -f`、`fcitx5-remote -r`、主题文件检查
~~[x] 采用 GTK 文件夹图标方案 B：继续生成 Matugen 图标，但不自动修改全局 icon-theme 或 Flatpak override。~~ — Agent: pi / theme-clipboard, 日期: 2026-08-20；验证: Matugen smoke test、GSettings icon-theme 保持 Breeze

~~[x] 增加 `home/.config/scripts/dot-doctor.sh` 健康检查。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `dot-doctor.sh`，0 errors
~~[x] 检查 `cliphist`、`wl-paste`、`ddcutil`、`pactl`、`waypaper`、`wl-screenrec` 等命令。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: doctor optional dependency section
~~[x] 检查 `clipsync-git`、`niri-sidebar`、`nirinit`、`niriusd` 等组件。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: command/service checks
~~[x] 对可选功能使用清晰的依赖提示，而不是启动后静默失败。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: doctor warnings，当前提示 clipsync-git 缺失

### P2-2：包清单拆分

~~[x] 保留 `packages/pkglist.generated.txt` 和 `packages/foreign-pkglist.generated.txt` 作为当前机器快照。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: bootstrap dry-run
~~[x] 增加 core、Niri、desktop、laptop、NVIDIA、AUR 手工 profile。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `bootstrap.sh --dry-run --profile core,niri`
~~[x] 让 bootstrap 默认安装 generated lists，并用 `--profile` 显式增加手工 profile。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `bash -n`、ShellCheck、dry-run
~~[x] 生成包列表时排序、去重，并保留手工声明与自动生成结果的边界。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: `collect_packages` 去重逻辑
~~[x] 增加 `--aur-helper auto|paru|yay`，支持显式选择 helper；默认 paru 优先、yay fallback。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `bootstrap.sh --dry-run --aur-helper paru`

### P2-3：Systemd 生命周期

~~[x] 为仓库管理的 user units 建立统一清单 `systemd-user-units.txt`。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: setup/uninstall 读取同一清单
~~[x] setup、uninstall 共用这份清单；doctor 检查清单中的关键 unit。~~ — Agent: pi / audit-fix, 日期: 2026-08-19；验证: dry-run、doctor
~~[x] 按服务类型绑定图形会话：random wallpaper、awww overview、swayidle 跟随 `graphical-session.target`；dotfiles autocommit 保持独立。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: systemd unit 检查
~~[x] setup 默认不启用 units，使用 `--enable-units` 或 `--enable-units=...` 显式启用。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `setup.sh --dry-run`

### P2-4：验证矩阵

- `[ ]` 增加 shell、JSON/JSONC、KDL、systemd unit、Python 的静态检查。
~~[x] 增加 Stow 部署的临时 HOME 集成测试。~~ — Agent: user + pi / audit-fix, 日期: 2026-08-19；验证: `tests/stow/integration.sh`
- `[ ]` 增加 setup/uninstall 的 dry-run 测试。
- `[ ]` 增加没有 Wayland、没有可选依赖时的降级测试。

### P2-5：壁纸脚本模块化重构

~~[x] 拆分 `random-anime-wallpaper.sh` 公共逻辑为 `wallpaper-lib.sh`（锁/通知/waypaper 同步/post-command），`random-api-wallpaper.sh` 同步复用；超分判断改为对比显示器实际分辨率（`niri msg -j outputs`，fallback 2200，90% 余量）；下载壁纸经 ImageMagick 统一转 JPG（quality 93 + auto-orient）。 — Owner: TraeCode / trae-glm, 日期: 2026-08-28；验证: `bash -n`、`shellcheck -S error`、lib 冒烟测试（flock 互斥、waypaper 读写含 `&` 转义、PNG→JPEG 转换）、niri jq 表达式实测 2560；修复初版 jq 表达式顶层结构错误~~

~~[x] 壁纸源池巡检：实测 11 个既有源全部存活；新增 zhuqiy / horosama / 98qy 三个实测可用的二次元壁纸源（moelm、btstu、seovx、vvhan、yimian、oick 等候选实测不可用已排除）。 — Owner: TraeCode / trae-glm, 日期: 2026-08-28；验证: curl 实测各源返回有效图片（≥20KB image/*）、`bash -n`、`shellcheck -S error`~~

~~[x] 修复 overview 模糊背景与当前壁纸不一致：timer 路径（random-api-wallpaper.service, Type=oneshot）中 nohup 异步拉起的 post-command 子进程被 KillMode=control-group 连坐杀死，请求文件不更新导致 matugen/模糊背景停留在旧壁纸（timer 历史选图全部无模糊缓存佐证）；wallpaper-lib.sh 的 wallpaper_run_post_command 改为同步前台调用（post 脚本仅写请求文件，重活在常驻 wallpaper-theme.service，同步代价毫秒级）。 — Owner: TraeCode / trae-glm, 日期: 2026-08-28；验证: 请求文件更新为当前壁纸、colors.kdl 与当前壁纸模糊缓存生成、`bash -n`、`shellcheck -S error`~~

~~[x] 壁纸脚本性能优化：(1) 下载脚本去重改增量哈希缓存 `.wall_hashes`（size:mtime 签名，变更自愈，消除随图库增长的每次全库 sha256 扫描）；(2) 下载/本地随机两脚本统一 `wallpaper-switch` 锁，消除并发互踩 waypaper 记录与壁纸文件的竞态；(3) realesrgan 超分改 `-f jpg` 直出（失败自动回退 PNG+转码）；(4) 合并重复 identify 调用（validate_geometry 一次取宽高回填全局，matugen-update 同样合并）；(5) 自动切换优先直调 awww img + waypaper 记录同步，失败回退 waypaper --no-post-command，单次切换 0.71s→0.25s；(6) 清理循环改 sed -z + xargs -0，blur 脚本 awww query 单次调用 + 纯 bash 解析。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: `bash -n`、`shellcheck -S error`、端到端真实下载（直出 JPG 超分生效、缓存登记 130 条）、哈希缓存增量冒烟（首轮建档/变更重算/重复识别）、清理管道特殊文件名测试、awww query 新旧解析等价测试、CodeReview 无阻塞问题（建议项已修复）~~

### P2-6：niri/scripts 与 scripts 目录脚本健康度修复（性能/健壮性/头部注释）

~~[x] 脚本健康度修复：(1) hyprlock-music 每 2 秒 N+1 个 playerctl 子进程合并为单次 --ignore-player 调用（保持只认 Playing 语义）；(2) screenshot 等待超时 10s→60s 并改为防挂死兜底、保存路径加文件存在性校验、旧版分支补超时、补头部注释；(3) auto-update-cache 补 close_write/moved_to 事件（编辑器原子保存与 sed -i 均为 rename）+ flock 多实例锁 + 通知失败不再杀链；(4) toggle-touchpad 加状态检测函数与 sed 前后校验（失败如实报错）、正则容忍 // 后任意空格、消除行尾注释重复累积；(5) swayidle 头部 15/25 分钟过期数值修正为实际 10/20；(6) 删除 niri_auto_blur_bg.sh 死链接（现役脚本符号链接，零调用方）；(7) matugen-select-type 补中文头部+状态文件原子写+共享写锁+fuzzel 失败与取消区分；(8) random-api-wallpaper 补头部；(9) waybar-reload-colors 加 flock 防 4 处调用方并发写；(10) gtk-theme-by-time writable 检查实效化+幂等写入+仅变更时重启 fcitx5；(11) nirinit-restore 补二进制检查/探活防假成功、pkill 后等真正退出；(12) toggle-overview-blur 删冗余 sleep 1+结果校验；(13) fcitx5-session-theme 仅变更时重启+tmp 清理 trap+XDG 路径一致。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: `bash -n`、`shellcheck -S error`、hyprlock-music 实测、toggle-touchpad 往返冒烟（完全还原）、锁互斥冒烟、waybar/fcitx5/gtk 幂等冒烟、CodeReview~~

~~[x] 修复超分直出 JPG 引入的重复壁纸回归：realesrgan 直出 jpg 成功（及 PNG 转码失败退回 PNG）时未删除原始下载文件，库内同时留下原图与 2x 超分版两张内容相同照片（实测 3 对，均为 2026-09-02 优化后产生）；修复为超分产物替代原图时删除原图，并清理现存重复对（保留高分辨率超分版）。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: `bash -n`、`shellcheck -S error`、库内成对检查归零、awww/哈希缓存一致性不受影响~~

### P0-7：剪贴板 TUI 快捷键显示和交互修复

~~[x] 修复四项问题 + 两个行为调整：(1) 星标与内容间距过大 — `--tabstop=1`；(2) 快捷键显示不全 — 双行 header + `^` 符号；(3) Enter 后窗口卡住空白 — `wl-copy 2>/dev/null` 防止 daemon 持有 PTY；(4) Ctrl-F 粘贴功能（已在 header 中宣传但未实现）；(5) 星标条目置顶 — `build_menu` 两遍扫描，先输出星标再输出普通；(6) 星标删除需确认，普通直接删 — `Ctrl+X` 检查 `is_pinned`。注意：`--no-clear` 尝试修复 Enter 后空白但导致箭头键/Esc 无法使用，已回退。 — Agent: ZCode / zcode-agent, 日期: 2026-08-20；验证: `bash -n`、`shellcheck -S error`、kitty 窗口关闭测试~~

### P2-7：waybar 脚本健康度修复

~~[x] (1) power-screenshot 截图完成检测无限轮询改 90s 超时防孤儿；补头部注释；(2) cava.sh 锁失败改 30s 低频重试接管，binds.kdl Mod+F2/F4 连杀 cava.sh 包装（pkill 模式锚定运行时绝对路径+行尾防误杀编辑仓库同名文件的进程），消除孤儿锁致模块永久失效；(3) check-updates JSON 缓存 tmp+mv 原子写（waybar 锁外直读）、tooltip 转义补反斜杠（实测修正双重转义回归）、>50 条分支恢复 head 截断；(4) pacman hook pkill 收紧为 /home/mio 绝对路径+行尾（hook 以 root 运行不能用 $HOME）；(5) screenrec tick 引擎崩溃时二次确认后清理 PIDFILE 并归位 waybar 图标（含 start_rec 重写毫秒窗口防误删）、8 个配置读取改 load_user_config 按需加载（status-json 每秒刷新省 ~60% forks）；(6) screenshot.sh grim 失败时先落盘校验再写剪贴板，不再覆盖为空；(7) 删除零调用方死代码 old-longshot.sh（中键实际用 wl-longshot）。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: `bash -n`、`shellcheck -S error`、`niri validate`、generate_json 函数级冒烟（80 条截断/特殊字符转义/JSON 合法）、screenrec status-json/is-active/help 实测、hook Exec sh 语法实测、CodeReview 5 项发现全部修复并复测~~

### P2-8：waybar 配置全面修复与重构

~~[x] (1) divider 实例名数字后缀全部改 p 前缀（waybar 把实例名注册为 CSS class，GTK4 拒绝数字开头选择器——GTK4 实测旧版 19 个 parser error、修复后 0），config.jsonc 14 处引用与 style.css 17 处选择器三方同步，powerline 配色首次真正生效；(2) modules-right 接入 group/audio 音量滑块抽屉；(3) dead config 清理 8 个未引用模块定义 + 6 个未引用 divider + style.css 死样式（swaync/mako/settings/clock.date/datelogo 等）；(4) updates 中键 pkill 锚定运行时绝对路径+行尾（与 pacman hook 一致）；(5) battery format-icons 补齐官方 11 元素（修复 90-99% 显示满电图标）；(6) mpris tooltip 类型修正、applauncher || 链精简、旧用户名注释清理、niri-taskbar 样式保留备用并注明；(7) modules.jsonc 滚轮音量 wpctl 加 -l 1.0 限幅。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: 三文件 JSONC 解析+引用一致性（36 引用无缺失、唯一未引用为有意保留的 mpris）、GTK4 CssProvider 加载（0 parser error）、waybar 实启动日志无相关错误、CodeReview 无阻塞问题~~

## 已知但暂不处理的问题

以下问题已在 2026-08-20 的 dotfiles 审查中确认，当前不在 Stow 链接修复范围内，后续按优先级处理，避免与本次部署修复混在一起：

- `[ ]` 统一 Node 版本管理器：`home/.config/zsh/integrations.zsh` 和 `home/.config/fish/conf.d/50-tools.fish` 仍同时初始化 `mise` 与 `fnm`，且文档与维护记录声明不一致；建议统一采用 mise。
- `[ ]` 统一脚本扩展名与解释器：`home/.config/niri/scripts/kbd-backlight-color.sh` 实际是 Fish 脚本；建议改名为 `.fish` 并同步调用方，避免 Bash/ShellCheck 误报。
- `[ ]` 拆分 Stow 包：当前 `home/` 一次部署全部 Shell、Niri、主题和可选功能；建议拆分 `home-core`、`home-niri`、`home-dev`、`home-theme` 等按需部署的包。
- `[ ]` 分离通用配置与主机配置：审查 `output.kdl` 的显示器参数、NVIDIA/Clevo/触控板配置，以及 `autostart/stop-niri-session-services.desktop` 中的 `/home/mio` 绝对路径。
- `[ ]` 简化 Shell 工具链：在 Zsh/Fish、Zinit/Fisher、fzf/Atuin、carapace、Starship 等重复能力中明确主方案，减少启动时网络访问和运行时初始化。
- `[ ]` 将 `packages/pkglist.generated.txt` 与 foreign 快照明确标记为当前机器快照；默认 bootstrap 应优先使用精简 profile，避免新机器安装当前机器的全部软件。
- `[ ]` 审查 Matugen、动态壁纸、GTK/Fcitx5 定时主题和 Niri/Systemd 双重生命周期，明确基础功能与可选增强功能的边界。
- `[ ]` 清理未使用或疑似遗留脚本（`niri_auto_blur_bg.sh` 与 `waybar/scripts/old-longshot.sh` 均已确认零调用方并于 2026-09-02 删除）
- `[ ]` 复核 `home/.gitconfig` 中当前工作区新增的 `safe.directory = *`；通用配置不应默认信任所有 Git 仓库。
- `[ ]` 扩充真实 HOME 场景的 Stow/Setup/Uninstall 测试，覆盖普通文件冲突、断链、动态生成文件和无 Wayland/可选依赖场景。

## 协作前置检查

创建本计划时，工作区已有以下修改，后续 Agent 不得擅自还原：

```text
M  home/.config/Code/User/settings.json
M  home/.config/niri/output.kdl
M  home/.config/zsh/.zshrc
?? home/.config/fish/conf.d/fnm.fish
```

建议在开始并行开发前，先由仓库负责人决定这些修改是：

1. 保留并单独提交；
2. 放入某个任务；
3. 还原；
4. 放入本地 overlay，不进入通用仓库。

## Definition of Done

一个任务只有同时满足以下条件，才可以改成删除线完成状态：

- 代码或文档修改已完成；
- 任务范围内的验证命令通过；
- 没有覆盖其他 Agent 的修改；
- 没有新增密钥或机器私有数据；
- 本文已记录 Agent、日期、修改文件和验证结果；
- 如果存在已知限制，已写入“已知但暂不处理的问题”。
