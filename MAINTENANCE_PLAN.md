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
> 2026-09-05 补记（ZCode CLI / zcode-20260905）：P0-6 当时只完成了 zsh 侧收敛，fish 侧 50-tools.fish 仍 mise+fnm 并存（任务记录与实况不一致的来源）。负责人已改拍板为「统一 fnm、mise 移出初始化」，由 P3-13 完成闭环。

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

~~[x] 壁纸脚本统一日志：wallpaper-lib.sh 新增 `wallpaper_log` / `wallpaper_log_init`（日志 `~/.local/state/wallpaper/wallpaper.log`，超 4000 行轮转保留最近 2000 行，写失败静默不影响主流程）；random-anime-wallpaper.sh 记录运行参数、逐源尝试与具体失败原因（curl 退出码 / JPG 归一化失败 / 无效图片 / 几何不符 / 重复哈希，校验链重构为 `check_download_result` 供主循环与保底源复用）、下载成功摘要（源 / 文件 / 尺寸 / 大小 / sha256 / 最终 URL）、超分决策与结果（原图尺寸 → 2x 产物文件名）、应用成功/失败、清理数量；random-api-wallpaper.sh 记录选择与应用结果（awww / waypaper 回退）与错误分支。 — Owner: TraeCode / trae-glm, 日期: 2026-09-10；验证: `bash -n`、`shellcheck -S error`、假 HOME 沙箱端到端（horosama 1920x1080 → realesrgan 超分 3840x2160 → awww shim 应用，全链日志正确落盘）、未知源错误路径、本地随机切换冒烟（waypaper 记录同步不受影响）、4100 行轮转实测保留最近 2000 行~~

### P0-7：剪贴板 TUI 快捷键显示和交互修复

~~[x] 修复四项问题 + 两个行为调整：(1) 星标与内容间距过大 — `--tabstop=1`；(2) 快捷键显示不全 — 双行 header + `^` 符号；(3) Enter 后窗口卡住空白 — `wl-copy 2>/dev/null` 防止 daemon 持有 PTY；(4) Ctrl-F 粘贴功能（已在 header 中宣传但未实现）；(5) 星标条目置顶 — `build_menu` 两遍扫描，先输出星标再输出普通；(6) 星标删除需确认，普通直接删 — `Ctrl+X` 检查 `is_pinned`。注意：`--no-clear` 尝试修复 Enter 后空白但导致箭头键/Esc 无法使用，已回退。 — Agent: ZCode / zcode-agent, 日期: 2026-08-20；验证: `bash -n`、`shellcheck -S error`、kitty 窗口关闭测试~~

### P2-7：waybar 脚本健康度修复

~~[x] (1) power-screenshot 截图完成检测无限轮询改 90s 超时防孤儿；补头部注释；(2) cava.sh 锁失败改 30s 低频重试接管，binds.kdl Mod+F2/F4 连杀 cava.sh 包装（pkill 模式锚定运行时绝对路径+行尾防误杀编辑仓库同名文件的进程），消除孤儿锁致模块永久失效；(3) check-updates JSON 缓存 tmp+mv 原子写（waybar 锁外直读）、tooltip 转义补反斜杠（实测修正双重转义回归）、>50 条分支恢复 head 截断；(4) pacman hook pkill 收紧为 /home/mio 绝对路径+行尾（hook 以 root 运行不能用 $HOME）；(5) screenrec tick 引擎崩溃时二次确认后清理 PIDFILE 并归位 waybar 图标（含 start_rec 重写毫秒窗口防误删）、8 个配置读取改 load_user_config 按需加载（status-json 每秒刷新省 ~60% forks）；(6) screenshot.sh grim 失败时先落盘校验再写剪贴板，不再覆盖为空；(7) 删除零调用方死代码 old-longshot.sh（中键实际用 wl-longshot）。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: `bash -n`、`shellcheck -S error`、`niri validate`、generate_json 函数级冒烟（80 条截断/特殊字符转义/JSON 合法）、screenrec status-json/is-active/help 实测、hook Exec sh 语法实测、CodeReview 5 项发现全部修复并复测~~

### P2-8：waybar 配置全面修复与重构

~~[x] 【注：divider 重命名已于同日应用户要求整体回滚——数字 class 规则此前虽被 GTK 丢弃，但用户已习惯该默认观感，规则生效反而改变显示效果；选择器同步回滚，仅保留死样式清理，见 revert 提交 769cf62】(1) divider 实例名数字后缀全部改 p 前缀（waybar 把实例名注册为 CSS class，GTK4 拒绝数字开头选择器——GTK4 实测旧版 19 个 parser error、修复后 0），config.jsonc 14 处引用与 style.css 17 处选择器三方同步，powerline 配色首次真正生效；(2) modules-right 接入 group/audio 音量滑块抽屉；(3) dead config 清理 8 个未引用模块定义 + 6 个未引用 divider + style.css 死样式（swaync/mako/settings/clock.date/datelogo 等）；(4) updates 中键 pkill 锚定运行时绝对路径+行尾（与 pacman hook 一致）；(5) battery format-icons 补齐官方 11 元素（修复 90-99% 显示满电图标）；(6) mpris tooltip 类型修正、applauncher || 链精简、旧用户名注释清理、niri-taskbar 样式保留备用并注明；(7) modules.jsonc 滚轮音量 wpctl 加 -l 1.0 限幅。 — Owner: Lingma / qoder-agent, 日期: 2026-09-02；验证: 三文件 JSONC 解析+引用一致性（36 引用无缺失、唯一未引用为有意保留的 mpris）、GTK4 CssProvider 加载（0 parser error）、waybar 实启动日志无相关错误、CodeReview 无阻塞问题~~

## P3 任务：历史遗留清理与缺失配置补全（2026-09-05 全库审查）

来源：2026-09-05 全方位审查（迁移考古 + 引用完整性 + 系统/仓库差距对比）。处理原则经仓库负责人确认：matugen 未安装软件的休眠模板全部保留（保持注释态，装软件后取消注释即可取色），只清理真正死代码。

~~[x] P3-1 修复 niri-sidebar 自启动路径~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: `home/.config/niri/config.kdl`（`~/.local/bin/` 硬编码 → PATH 解析）；验证: `niri validate` config is valid。注意：spawn-at-startup 需下次会话生效，本会话可按 `binds.kdl` 中的侧边栏快捷键手动拉起

~~[x] P3-2 修复 mimeapps.list 中 clash:// 协议指向不存在的 `clash-verge.desktop`~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: `home/.config/mimeapps.list`（[Added Associations] 与 [Default Applications] 两处均改为 `clash-verge-handler.desktop`，该 handler 显式声明两个 clash scheme 且为合法 desktop ID；`Clash Verge.desktop` 文件名带空格不是合法 ID）；验证: `xdg-mime query default x-scheme-handler/clash{,-verge}` 均返回 clash-verge-handler.desktop

~~[x] P3-3 清理 `.gitconfig` 的 `safe.directory = *` 与注释 gh-proxy 残留~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；验证: `git config --global --list` 无 safe.directory、解析正常

~~[x] P3-4 matugen 清理：删除 waybar post_hook 的 Win11Like 死代码、注释停用 swaylock-effects 模板块（模板文件保留）、为休眠模板块补充启用说明~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: `home/.config/matugen/config.toml`（post_hook 仅保留 waybar-reload-colors.sh；swaylock-effects 注释并注明「被 hyprlock 取代」；wlogout/qt5ct/qt6ct/color-scheme/niriswitcher 补「未安装：装 XXX 后取消注释启用」说明）；live 清理 `~/.config/waybar-niri-Win11Like/` 与 `~/.config/swaylock/config`；验证: tomllib 解析 OK、18 个活跃模板、swaylock-effects 不再生成

~~[x] P3-5 删除 vim 配置包~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: `git rm -r home/.config/vim`（11 文件，git 历史可找回）；live 清理 `~/.config/vim/`（含空目录残留）；验证: EDITOR 全链为 nvim（environment.d/10-shell.conf、zsh/env.zsh）、全仓库 grep 无 `.config/vim` 引用

- `[?]` P3-6 卸载遗留包 cliphist-tui-git、swaylock-effects 并刷新包快照 — 阻塞：Agent 运行环境无 sudo 权限。需仓库负责人执行：`sudo pacman -Rns cliphist-tui-git swaylock-effects` 后运行 `bash update-pkglist.sh` 刷新两份包快照。前置复核已完成：全仓库无脚本活跃引用 swaylock/cliphist-tui（rule.kdl 仅注释提及），`cliphist.service`（随包的系统 unit）本就处于 disabled — Owner: 待负责人

~~[x] P3-7 清理仓库改名遗留的 live 悬空软链与全注释占位文件 im.conf~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: rm `~/.config/scripts/niri_auto_blur_bg.sh`、`~/.config/waybar/scripts/old-longshot.sh`（均确认悬空）；`git rm home/.config/environment.d/im.conf`；核实 `~/.local/bin/env` 为 uv 产物且被 `home/.config/bash/bashrc:35` source（保留）、`env.fish` 为 fish PATH 兜底（保留）；验证: `tests/stow/integration.sh` STOW_PASS

~~[x] P3-8 ghostty 配置 `config.ghostty` 改名为 `config` 使其生效~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: `git mv` + 文件头注释更正 + live 软链重建（`~/.config/ghostty/config` → 仓库）；验证: 软链可解析、全仓库无 `config.ghostty` 残留引用

~~[x] P3-9 入库游离配置：niri-clip.service + niri-clip/config.toml、aur-local-check.service/timer、xdg-desktop-portal/niri-portals.conf、xdg-terminals.list~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: 8 个文件从 live 复制入库并转 stow 软链（内容经 cmp 校验一致），`systemd-user-units.txt` 补登 3 个 unit，README 剪贴板章节由已废弃的 cliphist TUI 改写为 niri-clip；验证: `systemd-analyze verify` 通过、`systemctl --user daemon-reload` 后 niri-clip active/enabled、aur-local-check.timer enabled、TOML 解析 OK

~~[x] P3-10 入库 atuin 配置（config.toml + 主题）~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；验证: tomllib 解析 OK、无同步密钥类敏感字段、live 已转 stow 软链

~~[x] P3-11 增补 .gitignore 生成物规则~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；结果: 实证核验后零增补——候选生成物（starship.toml、kitty/current-theme.conf、zsh-abbr、wl-longshot 等）经 `readlink -f` 验证均为 live 独立文件而非 stow 软链路径，不会落入仓库工作树，现有黑名单已覆盖全部实际入库路径；工作区中的 `.zcode/` 忽略行系 ZCode 客户端会话开始时自行写入（非本 Agent 添加），予以保留

~~[x] P3-12 系统侧残留清理与游离配置收编（同日追加，仓库负责人逐项指定）~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: ① `home/.config/waypaper/config.ini` 入库并转 stow 软链，按负责人要求删除 5 个 `swww_transition_*` 字段（注意：waypaper 2.8 `config.py save()` 无条件写回全部 schema 字段，下次保存会原样写回，且换壁纸会持续改动此文件——已入库意味着这些变化会出现在 git diff/自动提交中）；② `home/.local/share/applications/clash-verge-handler.desktop` 入库并转软链（手写的 clash:// 协议处理器，此前换机即失，P3-2 的 mimeapps 修复依赖它）；③ 删除 `~/.config/Code - OSS/`（inject_vscode.sh 旧版 `pacman -Q code` 正则误匹配 visual-studio-code-bin 的化石，脚本现已用 grep -Fx 精确匹配）、`~/.config/bottom/`（bottom 已卸载）、仓库内 `.omo/` 会话垃圾（gitignored，删除后该工具运行仍会再生）；④ 更正 P3 审查中的两处误报：`~/.config/fcitx/dbus/*` 为运行中 fcitx5 的活跃运行时文件（勿删），`.omo` 实际仅 1 处 4 文件；验证: waypaper INI configparser 解析 0 个 swww 字段、两个软链 `readlink -f` 可解析、`xdg-mime query default x-scheme-handler/clash` 经新软链仍返回 handler、fcitx5 运行未受影响

~~[x] P3-13 双 shell 初始化统一 fnm、移出 mise~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；拍板: zsh/fish 并列主力（有意设计），Node 统一 fnm，mise 目前用不上；修改: `zsh/integrations.zsh`（删 mise 段）、`zsh/.zshrc` 头注释、`zsh/README.md` 4 处、`fish/conf.d/50-tools.fish`（init+预加载列表）、`fish/functions/fish-update-completions.fish`（映射表/managed_cmds/特殊处理块）、`fish/functions/fish-comp-doctor.fish`（2 列表，mise→zoxide）、`fish/README.md` 3 处；live 清理 `~/.cache/fish/init/mise.fish` 死缓存；mise 包本体保留不卸载。影响评估: mise installs 仅含 usage 组件、无语言工具链，fnm 有 Node v24.19.0；验证: `fish -n`/`zsh -n` 全部通过、`fish -c` 实测 conf.d 加载后 fnm 1.39.0/node v24.19.0 可用、全仓库 grep 无活跃 mise 引用（仅存历史记录注释）
~~[x] P3-14 P2-4 静态检查进 CI：systemd-analyze verify、TOML、JSONC、KDL（niri validate）~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: 新增 `tests/config/check_toml_jsonc.py`（本地/CI 共用，tomllib 动态发现 TOML 但排除 matugen 模板、JSONC 显式清单，字符串感知注释剥离）；`lint.yml` static-checks job 加 config 检查步骤（systemd verify + `is not executable` 预期噪音过滤，该过滤模式已在 systemd 257 上实证）+ 新增 `niri-kdl-validate` job（`container: archlinux/archlinux:base-devel` + pacman 装 niri，因官方 release 无预编译二进制）；验证: 本机 python 脚本 9 文件全过、CI 同代码 systemd 段 12 unit 全过、坏 unit 负例（未知键）被正确拦截、`niri validate` 本机通过（colors.kdl 缺失仅 WARN）、lint.yml YAML 解析 OK；CI 首跑待 push 后 GitHub 确认
~~[x] P3-15 README.md / HOW.md 对齐现状并结构规范化~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；修改: README 重写为入口页——文档导航表、CI badge、布局树按 `git ls-files` 实际清单重生成（补 atuin/niri-clip/waypaper/xdg-desktop-portal/xdg-terminals.list/pacman/autostart/.local 等 9+ 项、删 swaylock/vim/yazi/fastfetch/swayosd 等 5 项虚列、12 unit 数目落实）、fish 定位改「并列主力（有意设计）」、特性清单同步新 CI 能力、新增「休眠配置保留注释态」设计原则；HOW 更新——新增「从 live 收编已有文件」标准流程（P3-12 手法沉淀）与悬空软链排查注记、commit 示例全部改为 AGENTS.md 中英结合规范、修正缓存表中「fish 手写补全不跟踪」的事实错误（实为 41 个跟踪文件）、多机器差异补 P1-4-D 拍板注记、卸载清理引用 systemd-user-units.txt；验证: 文档引用的全部脚本 flag 与实际 `--help`/grep 输出核对一致（setup/bootstrap/uninstall）、9 个引用路径存在性检查通过、布局树 9 个目录抽查全中

~~[x] P3-16 niri 会话恢复（nirinit）健壮性修复：补配置映射 + 加固恢复脚本~~ — Agent: WorkBuddy / wb-agent-0911, 日期: 2026-09-11；修改: 新增 `home/.config/nirinit/config.toml`（含 5 条 `[launch]` 映射）、重写 `home/.config/niri/scripts/nirinit-restore.sh`；验证: `bash -n`、`shellcheck -S error`、真实二进制隔离实测、假进程分支实测（详见下）

背景（读 nirinit 源码 + 核对本机环境得出，两个独立问题）：

1. **恢复窗口时半数会静默失败。** nirinit 恢复的做法是把 `app_id` 直接当命令 exec，而 niri 的 spawn 只做 PATH 查找（`src/utils/spawning.rs` 里就是 `Command::new(command).args(args)`），完全不解析 `.desktop`。本机 `session.json` 的 10 个窗口中有 5 个 app_id 在 PATH 里根本不存在，即这 5 类窗口此前一直被静默丢弃，只在日志留一行 `window for ... did not appear within 5s`（且用户当前日志里连这行都没有，因为恢复记录出自更早的会话）。已补映射：`org.telegram.desktop→Telegram`、`QQ→linuxqq`、`com.mitchellh.ghostty→ghostty`、`Google-chrome→google-chrome-stable`、`pdf→wpspdf`（后者的 app_id 经本机唯一 PDF 阅读器 `wpspdf` 反查确认）。

2. **恢复脚本的四个缺陷。** (a) `pkill` 后只等 2s 便继续执行，旧实例仍存活时会再起一个 → 双实例同时周期写 `session.json`，本机日志第 83-91 行已实际出现交错的恢复记录。改为 SIGTERM 等 5s → 仍存活则 SIGKILL 等 3s → 仍在则中止退出，不再启动第二个实例；(b) 无防重入，连按 Mod+Shift+G 会并发跑两份恢复，补 flock（沿用 `swayidle.sh` / `auto-update-cache.sh` 的锁文件惯例，放 `$XDG_RUNTIME_DIR`）；(c) 头部注释写的快捷键是 `Mod+Alt+R`，实际绑定为 `Mod+Shift+G`，已改正；(d) `--save-interval 300` 与 `config.kdl` 的值重复硬编码，提为 `SAVE_INTERVAL` 变量；另外把单次 `sleep 0.5` 探活改为两段探活。

   关键实现细节：新增的 flock **必须**给 nirinit 加 `9>&-` —— 锁挂在 fd 9 的打开文件描述上，nirinit 是长期驻留子进程，一旦继承 fd 9 就永不释放锁，之后每次调用都会抢不到锁而静默退出（该隐患已用假进程实测复现）。

验证方法与结果：配置文件用真实二进制在 `XDG_DATA_HOME` 隔离环境下实测被接受（无 `failed to load config` WARN），并以"故意写错键名"作反向对照，证明该检测手段确实能发现问题；映射后 10/10 窗口的启动命令均可解析；flock 三种行为（防重入生效、继承 fd 会永久占锁、加 `9>&-` 后正常释放）与停止逻辑两条分支（正常退出 `escalated=0`、忽略 TERM 时升级 SIGKILL `escalated=1`）均用假进程隔离实测通过。过程中另查明：已安装的 nirinit 0.2.2 二进制含 `--no-restore`，但 crates.io 发布包 / git tag v0.2.2 / master 三份源码均无该参数，即该二进制是用比公开源码更新的本地源码构建的，故本次结论以二进制实测为准。

剩余风险：会话恢复的语义缺陷见 P3-17（本次未修）；未做真机端到端恢复（会杀掉正在运行的 nirinit 并重开全部应用），实际恢复效果待用户下次使用时确认。

~~[x] P3-17 nirinit 会话恢复的语义缺陷：恢复目标不是"上次会话"而是"当前会话"，会开出重复窗口~~ — 提出: WorkBuddy / wb-agent-0911, 日期: 2026-09-11；决定: 同日由仓库负责人采纳"方案 A 的加强版"（冻结快照 + 智能跳过），已由 P3-18 实施完毕

  问题：nirinit 每 300 秒用【当前】窗口状态覆盖 `session.json`（源码 `save_session` 的 `skip_empty: false` 分支），所以开机满 5 分钟后文件里存的已经是当前会话；而 `restore_session` 对每个条目无条件 spawn（不判断"窗口是否已存在"），且随后的 `windows.iter().find(|w| w.app_id == app_id)` 会优先匹配到**已存在**的旧窗口，把那个旧窗口搬去目标工作区并改成快照里的尺寸。净效果：过了 5 分钟再按 Mod+Shift+G，会对已经在跑的应用再开一份，同时把原有窗口挪到别处 —— 行为不可预测。也就是说 `config.kdl` 里 `--no-restore` + 手动快捷键这套设计，实际只在"开机后、还没手动开窗口"这段窗口期内成立。

  候选方案（当时提出；最终决定见下方）：
  - **A. 只在开机时做一次快照**：开机阶段先把 `session.json` 复制成 `session.boot.json`，恢复脚本改从该快照恢复。语义变为"随时可恢复到上次关机时的状态"，且不再受 5 分钟窗口限制。代价是新增一个开机步骤和一份文件，需严格保证它与 nirinit 启动的先后顺序（必须在 nirinit 首次覆盖之前完成）。
  - **B. 保留现状，只做提示**：在恢复脚本里读当前窗口数，若非空则发一条"当前已有 N 个窗口，继续恢复会产生重复"的通知，行为不变。
  - **C. 跟随上游**：当前二进制比公开源码新且带未公开的 `--no-restore`，上游是否有相关改进需再确认。

  **最终决定（2026-09-11，仓库负责人）**：采用 A 的加强版 = **冻结快照 + 智能跳过**，并在排查中发现该二进制来源不可复现（详见 P3-18），因此同时弃用 `--no-restore`。方案 B 被否决，因为它的提示只覆盖"是否重复"这一个症状，不解决"恢复到的是当前会话"这个根因。

~~[x] P3-18 会话恢复重构：冻结快照 + 智能跳过；同时解除 stow 阻塞（承接 P3-17 与本文件中的 stow 冲突条目）~~ — Agent: WorkBuddy / wb-agent-0911, 日期: 2026-09-11；修改: 新增 `home/.config/niri/scripts/nirinit-start.sh`、重写 `home/.config/niri/scripts/nirinit-restore.sh`、改 `home/.config/niri/config.kdl` 的 spawn-at-startup、改 `home/.stow-local-ignore`；验证: `bash -n`、`shellcheck -S error`、`niri validate`、隔离功能测试 5 场景、stow 实跑、stow 漂移全量复核

  实现要点（三项改动互相咬合，缺一不可）：

  1. **冻结快照（解决"恢复的是当前会话"）**。新增 `nirinit-start.sh` 作为开机包装：把 `session.json` **移**成 `session.prev.json`（用 mv 不是 cp，移走后 nirinit 找不到会话文件才不会恢复），再 `exec nirinit --save-interval 300`。恢复脚本改从 `session.prev.json` 读取，于是"上次会话"名副其实，任何时间按都能恢复到上次关机时的状态。
     - 只在 `session.json` 是**非空数组**时才覆盖 `prev.json`。因为 nirinit 启动时会因找不到会话文件而立刻写一份新的（开机时通常是空的），拿它去覆盖会毁掉有用的快照。
     - 用 `$XDG_RUNTIME_DIR` 下的标记文件保证**每次登录只冻结一次**，避免 niri 重载配置时重复冻结、把"当前会话"当成"上次会话"覆盖掉真快照（`$XDG_RUNTIME_DIR` 是 tmpfs，注销即清空，重新登录自然重置）。
     - 同时加了 flock 防重入，并给 exec 前的 fd 9 做 `exec 9>&-` 解除占用。
  2. **智能跳过（解决"开出重复窗口"）**。恢复脚本先 `niri msg --json windows` 取当前已在跑的 `app_id`，再用一条 jq 表达式把 `session.prev.json` 过滤成只含**尚未运行**的窗口，写回 `session.json` 后重启 nirinit。于是反复按是幂等的；若快照里的应用全都已在运行，脚本直接提示"无需恢复"并**不触碰正在运行的 nirinit**。
     - 关键顺序：**必须先确认旧 nirinit 已退出，再写 `session.json`**。旧实例收到 SIGTERM 时会做最后一次保存、把当前窗口状态写进 `session.json`，若写入在前就会被覆盖掉。
     - 拿不到窗口列表时不静默照旧执行（那正是旧版的重复行为），降级为 fuzzel 确认。
  3. **弃用 `--no-restore`（消除换机风险）**。两处传给 nirinit 的参数现在只剩 `--save-interval`，该参数在上游 0.2.2 中存在；而"移走会话文件即不恢复"的行为由上游 0.2.2 的 `restore_session` 早退分支保证（源码 393-401 行）。因此换机 `cargo install --locked nirinit` 装到的原版同样可用。`config.kdl` 里留了注释警告不要改回传 `--no-restore`。

  顺带修掉的真实故障：`.stow-local-ignore` 增加 `\.config/waypaper/config\.ini$` 规则后，stow 不再整体中止，实跑补上了两个缺失链接 —— 其中 **`~/.config/scripts/wallpaper-lib.sh` 此前从未链接成功**，而 `random-anime-wallpaper.sh` 与 `random-api-wallpaper.sh` 都要 source 它，**壁纸脚本此前一直是坏的**（修复前实测报 `No such file or directory`，修复后 source 与 `wallpaper_log` 函数均正常）。

  验证方法与结果：隔离功能测试 5 场景全过 —— A 非空 session.json 被正确冻结且原文件消失；B 同一次登录内重复触发不会覆盖快照；C 空 `session.json` 不摧毁已有快照；D 过滤逻辑正确且 JSON 字段完整保留（实测 11 个窗口、已在跑 3 个 → 待恢复 8 个）；E 全部在跑时过滤为空、走"无需恢复"分支。测试用假 HOME + 替身二进制（shebang 脚本，comm 不为 nirinit）完成，**全程未运行真实恢复脚本、未触碰用户正在运行的 nirinit**。stow 漂移全量复核：修复前 353 正常 / 3 异常，修复后仅剩 `.stow-local-ignore` 一项（它是 stow 控制文件，本就不该出现在 live，属正常）。

  剩余风险：① 本次仍未做真机端到端恢复（会杀掉正在运行的 nirinit 并重开全部应用），实际效果待用户下次登录后按一次确认；② `config.kdl` 的 spawn-at-startup 改动需**重新登录或 niri 重启**才生效，在那之前按 Mod+Shift+G 会提示"还没有可恢复的会话快照"（优雅降级，不会出错）；③ 快照里同一应用有多个窗口（如两个 `code`）时，智能跳过只能按 app_id 整体判断，无法只补其中一个 —— 这是 nirinit 快照不含窗口标题/唯一标识的固有限制，见"已知但暂不处理"。


~~[x] P3-19 会话恢复改为"会话结束时保存一次"：新增 nirinit-flush.service，周期保存降为崩溃兜底；撤销手动固定布局~~ — Agent: WorkBuddy / wb-agent-0911, 日期: 2026-09-11；修改: 新增 `home/.config/niri/scripts/nirinit-flush.sh` 与 `home/.config/systemd/user/nirinit-flush.service`、改两个脚本的 `SAVE_INTERVAL`、改 `binds.kdl`、登记 `systemd-user-units.txt`、删除 `nirinit-save.sh`；验证: `bash -n`、`shellcheck -S error`、`niri validate`、`systemd-analyze verify`、PID namespace 内 3 场景实测

  需求（仓库负责人）：在关机和重启之前自动保存一次，不要每隔几分钟保存。

  **关键发现（否决了朴素实现）**：nirinit 随 niri 一起被杀时，它的收尾保存有 **55% 概率失败**。统计 `~/.local/share/nirinit/nirinit.log`：正常关闭 42 次，其中 **23 次**报 `Failed to send data to Niri's IPC socket: Connection reset by peer (os error 104)`。根因是 niri 的 IPC socket 比 nirinit 收到 SIGTERM 更早消失，nirinit 已经问不到窗口列表。**因此单纯去掉周期保存会让快照长期停在空/过期状态，功能直接退化。**

  **解法**：本机 niri 是 systemd user unit（`/usr/lib/systemd/user/niri.service`，`Type=notify`，`BindsTo`/`Before=graphical-session.target`），且仓库已有同套路的现役范例 `niri-clip.service`（`PartOf=graphical-session.target` + `After=graphical-session.target` + `WantedBy=niri.service`）。据此新增 `nirinit-flush.service`：
  - 顺序推导：`niri.service` 声明 `Before=graphical-session.target` ⇒ 它在会话目标**之后**停止；本单元 `After=graphical-session.target` ⇒ 它在会话目标**之前**停止。故本单元先停、niri 后停，**其 `ExecStop` 执行时 niri 仍活着** → 此时杀掉 nirinit，收尾保存必然成功。
  - `oneshot` + `RemainAfterExit=yes` + `ExecStart=/bin/true`，只在被停止时触发 `ExecStop`；`TimeoutStopSec=20`；`WantedBy=niri.service`，因此 KDE 等其它会话下不会误触发。
  - `nirinit-flush.sh` 的三条设计约束：幂等（nirinit 未运行时必须安全无操作退出）、不重启 nirinit（会话即将结束，下次登录由 `spawn-at-startup` 负责）、不用 `set -e`（关机钩子的非致命失败不该让单元失败或拖慢关机）。

  同时：`nirinit-start.sh` / `nirinit-restore.sh` 的 `SAVE_INTERVAL` 由 300 改为 **1800**，周期保存降级为"崩溃/断电/被强杀时的兜底"；撤销上一轮实现的手动"固定布局"（删除 `nirinit-save.sh`、`binds.kdl` 的 Mod+Shift+S、`nirinit-restore.sh` 的 saved.json 优先逻辑）——新语义下"摆好布局 → 关机"即等于保存，多一套概念只会增加困惑；`systemd-user-units.txt` 登记新 unit（`setup.sh` 据此 enable，且 `setup.sh --units` 会校验成员资格）。

  验证：三个脚本 `bash -n` + `shellcheck -S error` 通过；`niri validate` 通过；`systemd-analyze verify` 对 unit **无任何语法/未知键告警**（唯一一次告警是 `%h` 在 root 身份下解析成 `/root`，属环境因素）；`nirinit-flush.sh` 在 **PID namespace** 内实测 3 场景全过 —— 未运行时安全无操作退出且退出码 0、运行中时停掉替身并完成收尾保存（写入 2 个窗口）、替身忽略 SIGTERM 时升级 SIGKILL 清除。测试带**安全联锁**：进入 namespace 后先确认看不到外部 nirinit，否则立即中止，全程未触碰用户真实运行的实例。

  剩余风险：① **本环境无法验证 unit 的 enable 行为与停止顺序**（`systemd-analyze --user` 起不来，没有 user manager），顺序推导有 `niri-clip` 的实证支撑，但需实机确认；② **本会话尚未 start 该单元**（`.wants` 链接已按 `systemctl --user enable` 的格式预置），需 `systemctl --user daemon-reload` 后再 `enable --now` 才在当前会话生效；③ 崩溃/断电/`kill -9` 不走会话结束流程，flush 不执行，由 1800s 周期保存兜底，最多丢 30 分钟；④ `systemctl --user restart niri` 时会话目标不一定停止，flush 可能不触发（同上由兜底覆盖）。

~~[x] P3-20 唤醒后音频自愈兜底：audio-resume-guard.service 监听 logind PrepareForSleep，唤醒后延迟重启 WirePlumber~~ — Agent: ZCode CLI / zcode-20260914, 日期: 2026-09-14；修改: 新增 `home/.config/niri/scripts/audio-resume-guard.sh` 与 `home/.config/systemd/user/audio-resume-guard.service`、登记 `systemd-user-units.txt`

  背景（当日实证）：suspend-then-hibernate 的 s2idle→休眠切换瞬间 WirePlumber `alsa.lua` nil 崩溃后进入坏状态——内置声卡 profile 卡 off、蓝牙耳机（QCY H3）不建节点，所有声音进 `auto_null` 虚拟输出，表现为"耳机已连但无声"；`systemctl --user restart wireplumber` 即恢复（上游 0.5.8~0.5.17 反复出现的 alsa.lua nil bug 家族，非本机特有）。本任务把该手动修复自动化。

  实现要点：原计划写 `/etc/systemd/system-sleep/` 钩子，因 Agent 运行环境无 sudo（同 P3-6 结论）改为**用户级 D-Bus 监听**——`dbus-monitor` 订阅 logind `PrepareForSleep`，见 `boolean false`（唤醒）后 sleep 5 再 `systemctl --user restart wireplumber.service`（只重启设备管家、不动 PipeWire 本体）。**关键坑**：系统总线上非 root 的 dbus-monitor 无法启用 new-style monitoring，回退 eavesdropping 后**匹配规则失效、全总线信号都会打印**，因此不能用"单行含 boolean false"判断（PropertiesChanged 的 `variant boolean false` 会误触发）；已改为两行状态机：先见 `member=PrepareForSleep`、紧随其后的 `boolean false` 才触发。脚本带 `GUARD_TEST`/`GUARD_TEST_SRC` 离线测试钩子；流结束以非零退出交给 `Restart=on-failure` 拉起。

  验证：`bash -n` + `shellcheck -S error` 通过；`systemd-analyze --user verify` 通过；离线样例测试（含 4 个诱饵：`PrepareForShutdown`、两条 PropertiesChanged `variant boolean false`、挂起 `boolean true`）0 误触发、真唤醒事件恰好触发 1 次、EOF 退出码 1；服务 `enable --now` 后 active，实机 live。

  剩余风险：① 真实 suspend-then-hibernate 端到端未跑（需下次真实唤醒后查 `journalctl --user -u audio-resume-guard` 确认触发）；② 每次唤醒会重启 wireplumber，约 0.5s 音频中断（无声设备场景下无感知）；③ `sleep 5` 期间若再次入睡（实际不可能）事件会漏，由下次唤醒补上。

## 已知但暂不处理的问题

以下问题已在 2026-08-20 的 dotfiles 审查中确认，当前不在 Stow 链接修复范围内，后续按优先级处理，避免与本次部署修复混在一起：

~~[x] `stow -d ~/dotfiles -t ~ home` 曾整体中止、新增文件无法部署~~ — 2026-09-11 发现并同日由 P3-18 修复：在 `home/.stow-local-ignore` 增加 `\.config/waypaper/config\.ini$` 后冲突消失，stow 实跑补链成功。留档原文如下： 2026-09-11 由 WorkBuddy / wb-agent-0911 在 P3-16 期间发现：stow 预演报 `cannot stow dotfiles/home/.config/waypaper/config.ini over existing target .config/waypaper/config.ini since neither a link nor a directory`，随后 `All operations aborted`。原因是 P3-12 收编 waypaper 配置后，waypaper 运行时会用自身 schema 重写 `~/.config/waypaper/config.ini`（实测该文件已是 owner `mio` 的普通文件，且 `swww_transition_*` 五个字段被原样写回、`wallpaper` 路径也不同），链接因而断开。注意影响面：只要这一处冲突存在，**新增任何入库文件都无法用 stow 部署**（本次 P3-16 的 `config.toml` 只能按 stow 的相对链风格手工建链）。另 stow 预演还提示 `.config/scripts/wallpaper-lib.sh` 缺失待链。最终处理方式（2026-09-11，仓库负责人）：不采用 `--adopt`（会让 waypaper 的重写结果持续进入 git diff），改为让 stow **忽略**该文件——仓库内那份保留为"参考种子"，live 侧由 waypaper 自行维护。**遗留**：仓库副本与 live 会持续漂移且不再有链接关系，若将来 waypaper 配置需要随机器迁移，需另想办法（例如改名为 `.template` 由 setup 生成）。

- `[ ]` 会话快照无法区分同一应用的多个窗口：nirinit 的快照只记录 `app_id`（不含窗口标题等可区分标识），所以像"两个 VS Code 窗口"这种情况，P3-18 的智能跳过只能按 app_id 整体判断 —— 其中一个已经在跑时，另一个不会被补回来（2026-09-11 实测本机快照里 `code` 确有两条）。属 nirinit 数据结构层面的限制，非本仓库脚本能解决；若将来确实需要，只能跟上游或改用能记录标题的方案。
- `[ ]` `~/.config/waypaper/config.ini` 现已退出 stow 管理（仅被忽略、仓库内保留为参考种子），其 live 副本与仓库副本会持续漂移且无链接关系，换机时该文件的配置不会自动带过去。见上方 waypaper 条目。
~~[x] 统一 Node 版本管理器：`home/.config/zsh/integrations.zsh` 和 `home/.config/fish/conf.d/50-tools.fish` 仍同时初始化 `mise` 与 `fnm`，且文档与维护记录声明不一致。~~ — 2026-09-05 由 ZCode CLI / zcode-20260905 经 P3-13 闭环；最终拍板为统一 fnm（与本条目原建议的 mise 相反，负责人确认目前用不上 mise）；验证: fish -c 实测 + grep 无活跃 mise 初始化
- `[ ]` 统一脚本扩展名与解释器：`home/.config/niri/scripts/kbd-backlight-color.sh` 实际是 Fish 脚本；建议改名为 `.fish` 并同步调用方，避免 Bash/ShellCheck 误报。
- `[ ]` 拆分 Stow 包：当前 `home/` 一次部署全部 Shell、Niri、主题和可选功能；建议拆分 `home-core`、`home-niri`、`home-dev`、`home-theme` 等按需部署的包。
- `[ ]` 分离通用配置与主机配置：审查 `output.kdl` 的显示器参数、NVIDIA/Clevo/触控板配置，以及 `autostart/stop-niri-session-services.desktop` 中的 `/home/mio` 绝对路径。
- `[ ]` 简化 Shell 工具链：在 Zinit/Fisher、fzf/Atuin、carapace、Starship 等重复能力中明确主方案，减少启动时网络访问和运行时初始化。
  > 2026-09-05 拍板（仓库负责人）：zsh 与 fish 为并列主力 shell，双 shell 是有意设计，不作为遗留移除；Node 版本管理统一 fnm、mise 移出 shell 初始化（P3-13 执行，Node 子项就此闭环，本条目其余重复能力收敛继续保留）。
- `[ ]` 将 `packages/pkglist.generated.txt` 与 foreign 快照明确标记为当前机器快照；默认 bootstrap 应优先使用精简 profile，避免新机器安装当前机器的全部软件。
- `[ ]` 审查 Matugen、动态壁纸、GTK/Fcitx5 定时主题和 Niri/Systemd 双重生命周期，明确基础功能与可选增强功能的边界。
~~[x] 清理未使用或疑似遗留脚本（`niri_auto_blur_bg.sh` 与 `waybar/scripts/old-longshot.sh` 均已确认零调用方并于 2026-09-02 删除）~~ — 2026-09-05 由 ZCode CLI / zcode-20260905 补充清理 live 侧悬空软链后闭环；验证: `tests/stow/integration.sh`
~~[x] 复核 `home/.gitconfig` 中当前工作区新增的 `safe.directory = *`；通用配置不应默认信任所有 Git 仓库。~~ — Agent: ZCode CLI / zcode-20260905, 日期: 2026-09-05；已实际删除（P3-3）；验证: `git config --global --list`
- `[ ]` shell init 缓存目录属主为 root，缓存自愈机制已失效：`~/.cache/zsh/init/` 与 `~/.cache/fish/init/`（含 atuin/carapace/starship 等缓存文件）为 `root:root`（755/644），`mio` 只读不可写。疑似此前某次 Agent 会话以 root 身份、`HOME=/home/mio` 跑过交互 shell 所致（fish 目录创建于 2026-09-05 10:47，与 zcode P3-10 同日）。后果：工具二进制更新后 zsh 侧 `_zsh_cached_init` 重建失败会 `return 1`（该工具 init 整个不加载，Ctrl+R 退回原生搜索），fish 侧会继续 source 过期缓存脚本。2026-09-12 由 WorkBuddy / wb-agent-0912 在 Atuin 共享历史审计中发现（Atuin 双 shell 共享本身正常：`history.db` 内 zsh 668 + fish 1030 条记录、无 `db_path` 覆盖、`filter_mode=global`）。修复建议（需负责人执行）：`sudo rm -rf ~/.cache/zsh/init ~/.cache/fish/init`（缓存可再生，下次 shell 启动会以正确属主重建）；属 live 机器状态问题，非仓库文件。
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
