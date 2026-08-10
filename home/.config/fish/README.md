# Fish Shell 配置

Arch Linux 上的 fish 4.8.1 配置。设计原则：**conf.d 模块化 + 工具自带补全优先 + Material You 动态配色**。

---

## 目录结构

```
~/.config/fish/
├── config.fish                       主入口（保持极简，所有逻辑在 conf.d/）
├── fish_plugins                      Fisher 插件清单（5 个）
├── fish_variables                    Fish universal 变量
├── conf.d/                           按字母序自动加载的配置模块
│   ├── 00-env.fish                   环境变量（fish 特有 + XDG 兜底）
│   ├── 10-paths.fish                 PATH（~/.local/bin 等）
│   ├── 20-abbreviations.fish         缩写（abbr，按空格展开）
│   ├── 25-aliases.fish               别名（安全标志 + 透明替换）
│   ├── 35-pager.fish                 Pager 配色说明（已迁移到 matugen）
│   ├── 35-pager-matugen.fish         ← matugen 自动生成，勿手改
│   ├── 40-fzf.fish                   FZF 主题 + 预览
│   ├── 50-tools.fish                 工具初始化（starship/zoxide/atuin/carapace...）
│   ├── 60-cnf.fish                   command-not-found 处理（pkgfile）
│   ├── autopair.fish                 ← Fisher 插件
│   ├── done.fish                     ← Fisher 插件
│   ├── fzf.fish                      ← Fisher 插件
│   └── sponge.fish                   ← Fisher 插件
├── completions/                      工具自带补全（51 个文件，fish-update-completions 生成，已入库）
├── functions/                        自定义函数 + 插件函数
│   └── fish_user_key_bindings.fish   键绑定（fish 官方覆盖点，见下文）
└── themes/                           （空，配色由 matugen 动态注入）
```

**加载顺序**：`conf.d/` 按文件名字母序（数字优先）在 `config.fish` 之前加载（fish 4.x 官方行为，
见 `share/config.fish` 末尾的 conf.d source）→ `functions/` 按需自动加载 →
第一个 prompt 显示时执行 `fish_user_key_bindings`（`__fish_config_interactive` 调用，
在 conf.d 之后，用于覆盖插件绑定）。

**键绑定覆盖机制**（2026-08 重构，替代原 `zz-bindings-override.fish`）：

```
conf.d/ 加载（fzf.fish 注册 ctrl-alt-*、atuin 注册 ctrl-r）
    ↓
第一个 prompt → __fish_config_interactive
    ↓
__fish_reload_key_bindings
    ├─ $fish_key_bindings（默认绑定）
    └─ fish_user_key_bindings（自定义覆盖，最后执行）
```

---

## 快速上手：5 分钟掌握核心

### 1. 缩写（abbr）- 按空格自动展开

输入缩写 + 空格，自动展开为完整命令（你能看到展开后的内容）：

```
g<space>        ->  git
g s<space>      ->  git status        # 只在 git 后展开
g cm<space>     ->  git commit -m
ll<space>       ->  eza -l --icons --group-directories-first --git --time-style=long-iso
v<space>        ->  nvim
..<space>       ->  cd ..
...<space>      ->  cd ../..
c<space>        ->  clear
pacup<space>    ->  sudo pacman -Syu
```

查看所有缩写：`abbr` 命令。
编辑缩写：`fishabbr`（展开为 `$EDITOR ~/.config/fish/conf.d/20-abbreviations.fish`）。

### 2. 透明替换工具（alias）

这些命令已被现代化工具替换，但你**仍然输入原名**：

| 你输入 | 实际执行 | 备注 |
|---|---|---|
| `ls` | `eza --icons --group-directories-first` | |
| `cat` | `bat --style=plain --paging=never` | |
| `du` | `dust` | |
| `df` | `duf` | |
| `top` | `btop` | |
| `rm` | `rm -I` | **删除前确认** |
| `cp` | `cp -iv` | 详细 + 确认 |
| `mv` | `mv -iv` | 详细 + 确认 |
| `mkdir` | `mkdir -pv` | 自动创建父目录 |
| `ip` | `ip --color=auto` | |
| `diff` | `diff --color=auto` | |

**故意不替换**的工具（注释里有说明）：`grep`/`find`/`ps` - 语义不兼容会破坏管道和脚本。

### 3. Tab 补全

按 `Tab` 打开补全菜单。**关键技巧**：

| 按键 | 行为 |
|---|---|
| `Tab` | 补全 / 打开菜单 |
| `Shift-Tab` | 补全 + **立即进入搜索模式**（输入子串过滤） |
| `Ctrl-S` | pager 打开后切换搜索模式 |
| `↑` `↓` `←` `→` | 在菜单中导航 |
| `Tab` / `Shift-Tab` | 在菜单中移动选中项 |
| `Enter` | 确认选择 |
| `Esc` / `Ctrl-C` | 取消 |

pager 配色由 matugen 动态生成（见下文"配色"章节）。

### 4. fzf 全屏搜索（Ctrl 系列绑定）

fzf.fish v11 默认键位（`fzf_configure_bindings` 注册，default + insert 双模式）：

| 按键 | 功能 | 说明 |
|---|---|---|
| `Ctrl-R` | 历史命令搜索 | **被 atuin 接管**（SQLite + 模糊 + 跨机同步），覆盖 fish 默认的 history-pager，见 `functions/fish_user_key_bindings.fish` |
| `Ctrl-Alt-F` | 目录/文件搜索 | bat 预览 |
| `Ctrl-Alt-L` | git log 搜索 | |
| `Ctrl-Alt-S` | git status 搜索 | |
| `Ctrl-Alt-P` | 进程搜索 | 注意：fcitx5 的 `TogglePreedit` 可能拦截此键 |
| `Ctrl-V` | 变量搜索 | 覆盖 fish 默认的 fish_clipboard_paste |

> ⚠️ **Ctrl-Alt-P 与 fcitx5 冲突**：fcitx5 的 `TogglePreedit`（切换预编辑显示模式：内联 ↔ 弹出窗口）在 Wayland 层可能拦截这个组合键。
> 若无效，进程搜索改用 `fkill` 命令（fzf 交互式杀进程，见下文"命令参考"）。

### 5. 行编辑（fish 4.x 默认 emacs 风格）

| 按键 | 功能 |
|---|---|
| `Ctrl-A` / `Ctrl-E` | 行首 / 行尾 |
| `Ctrl-B` / `Ctrl-F` | 后退 / 前进一个字符 |
| `Ctrl-Left` / `Ctrl-Right` | 按 token 移动光标 |
| `Home` / `End` | 行首 / 行尾 |
| `Ctrl-Backspace` | 删除前一个 token |
| `Ctrl-Delete` | 删除后一个 token |
| `Backspace` / `Ctrl-H` | 删除前一个字符 |
| `Ctrl-W` | 删除前一个路径段（按 `/` 切分） |
| `Ctrl-U` | 删除光标到行首 |
| `Ctrl-K` | 删除光标到行尾 |
| `Ctrl-T` | 字符交换（fish 默认；fzf.fish 未占用此键） |
| `Alt-Backspace` | 删除前一个词 |
| `Alt-D` | 删除后一个词 |
| `Alt-T` | 交换前后两个词 |
| `Alt-U` | 大写化光标后词 |
| `Alt-C` | 首字母大写（fish 默认；fzf.fish 未占用此键） |

### 6. 历史、撤销与编辑器辅助（fish 4.x 默认）

| 按键 | 功能 |
|---|---|
| `Ctrl-P` / `Ctrl-N` | 上一条 / 下一条历史（带前缀搜索） |
| `Alt-Up` / `Alt-Down` | 历史 token 搜索（前 / 后） |
| `Alt-.` | 插入上一条命令最后一个参数 |
| `PageUp` / `PageDown` | 跳到历史首 / 末 |
| `Alt-<` / `Alt->` | 跳到缓冲区首 / 末 |
| `Ctrl-Y` / `Alt-Y` | yank / yank-pop（粘贴删除环） |
| `Ctrl-/` / `Ctrl-Z` | 撤销 |
| `Ctrl-Shift-Z` / `Alt-/` | 重做 |
| `Ctrl-X Ctrl-E` 或 `Alt-E` / `Alt-V` | 在 `$EDITOR` 中编辑当前命令行（`functions/fish_user_key_bindings.fish` 显式绑了前者，后者是 fish 内建） |
| `Alt-S` | 在命令前加 `sudo`（fish 内建，循环尝试 `sudo` / `doas` / `please` / `run0`） |
| `Alt-H` 或 `F1` | 打开当前命令的 man page |
| `Alt-W` | 查看当前 token 的 man（whatis） |
| `Alt-L` | 列出当前 token 对应的文件 / 目录 |
| `Alt-O` | 用 pager 预览当前文件 |
| `Alt-P` | 用 pager 分页当前命令输出 |
| `Alt-#` | 注释 / 取消注释当前行 |
| `Ctrl-L` | 清屏（带 scrollback 推送） |
| `Ctrl-C` | 清空当前命令行 |
| `Ctrl-D` | 删除后字符；空行时退出 shell |
| `Ctrl-G` / `Esc` | 取消当前命令 |
| `Ctrl-S` | pager 搜索模式切换（Tab 补全打开菜单后才生效） |
| `?` | atuin AI 帮助 |

> **关于"未生效"**：fish 4.x 的默认绑定**仅在交互模式**下由 `fish_default_key_bindings` 函数加载。
> 用 `fish -c 'bind'` 看到的是精简列表（非交互模式不加载默认绑定）。
> 要看完整绑定，需在交互 shell 内执行 `bind`，或 `fish -ic 'bind'`（注意 `-i` 是关键）。

autopair 已启用：输入 `(` `[` `{` `"` `'` 自动配对，按 backspace 删除一对。

---

## 命令参考：自定义函数

### 包管理

| 命令 | 功能 | 示例 |
|---|---|---|
| `apt` | Arch 包管理包装器（paru > yay > pacman 优先级） | `apt install firefox` / `apt update` / `apt remove foo` / `apt search rust` / `apt help` |

### 文件与目录

| 命令 | 功能 | 示例 |
|---|---|---|
| `y` | yazi 文件管理器（退出时 cd 到最后浏览的目录） | `y` / `y ~/Pictures` |
| `mkcd` | 创建目录并进入 | `mkcd projects/foo` |
| `lt` | 树状列出（eza --tree） | `lt` |
| `extract` | 通用解压（自动识别格式） | `extract archive.tar.gz` |
| `br` | broot 文件浏览器（符号链接到 broot launcher） | `br` |

### 系统与进程

| 命令 | 功能 | 示例 |
|---|---|---|
| `fkill` | fzf 模糊搜索并杀进程 | `fkill` / `fkill SIGKILL` |
| `port` | 查看端口占用 | `port 8080` |
| `sysinfo` | 系统信息概览（OS/内核/内存/CPU/包数） | `sysinfo` |
| `weather` | 天气（默认武汉） | `weather` / `weather Beijing` |

### Git / Dotfiles

| 命令 | 功能 | 示例 |
|---|---|---|
| `dot` | 在 ~/dotfiles 仓库里执行 git 命令（普通 git 仓库，GNU Stow 部署） | `dot status` / `dot diff` / `dot push` |
| `dota` | `dot add` 简写（路径相对 $HOME） | `dota .config/fish/foo.fish` |
| `gitignore` | 从 toptal.com 拉取 .gitignore 模板 | `gitignore python,node` / `gitignore list` |

### 娱乐

| 命令 | 功能 |
|---|---|
| `f` | 随机二次元图片 + fastfetch 系统信息（自动缓存 + 后台补货） |
| `fwatch` | f 的连续模式（每 5 秒刷新） |

---

## 配色：Material You 动态主题

整套配色由 **matugen** 驱动，跟随壁纸自动变化。fish 已接入：

```
~/.config/matugen/templates/fish-pager.fish   ← 模板
    ↓ matugen 渲染
~/.config/fish/conf.d/35-pager-matugen.fish   ← 自动生成
```

**换壁纸时**：

```fish
matugen image /path/to/wallpaper.jpg
```

fish pager 配色会和其他工具（starship / kitty / ghostty / fuzzel / niri / yazi / nvim / mako / btop 等）一起重新生成。

pager / 命令行颜色映射设计（`~/.config/matugen/templates/fish-pager.fish`）：

| 元素 | Material You token | 含义 |
|---|---|---|
| 选中行背景 | `primary` | 亮色，对比强烈 |
| 选中行前景 | `on_primary` + `--bold` | 专为 primary 背景设计的文字色 |
| 补全前缀（命令） | `primary` | 每组补全的命令部分 |
| 斑马纹前缀 | `tertiary` | **偶数行的前缀**（fish 的 secondary_* 是隔行条纹，不是"选项列"！） |
| 补全文字 | `on_surface` | 主前景色 |
| 描述文字 | `on_surface_variant` | 次要文字色 |
| 命令语法色 | `primary`（command/builtin/function） | 命令行高亮 |
| 选项语法色 | `tertiary`（option/operator/escape） | 命令行高亮 |
| 引用/字符串 | `secondary` | 命令行高亮 |
| 自动建议 | `outline` | 灰色幽灵文本 |
| 错误 | `error` | 红色 |

> ⚠️ **fish 4.8 只有 13 个 pager 颜色变量**（highlight.rs 源码确认）：基础组 5 个 +
> `secondary_*` 4 个（**隔行斑马纹**，`row % 2 != 0` 触发）+ `selected_*` 4 个。
> **不存在 `tertiary_*` 变量**，设置会被静默忽略；pager 搜索高亮用
> `fish_color_search_match`（不存在 `fish_pager_color_search_match`）。
> 历史遗留：`35-pager.fish` 已清空为仅注释，实际配色由 `35-pager-matugen.fish` 接管。

---

## 补全系统：三层架构

```
Tab 触发补全
     ↓
1. 工具自带补全（completions/*.fish）    ← 最准，支持动态子命令
     ↓ 未注册时
2. carapace 兜底（2000+ 命令，on-demand）  ← 50-tools.fish 启动时注册
     ↓ carapace 未覆盖时
3. fish 默认（文件/路径补全）
```

### 健康检查

```fish
fish-comp-doctor           # 全局补全系统体检
fish-comp-doctor gh        # 诊断单个命令的补全来源
```

### 生成/更新工具自带补全

```fish
fish-update-completions           # 生成所有支持的工具补全
fish-update-completions gh        # 只生成指定工具
fish-update-completions --force   # 强制重建
fish-update-completions --clean   # 删除孤儿补全（工具已卸载的）
```

### 预加载关键命令补全

`50-tools.fish` 启动时会显式 source 一批关键命令的自带补全（opencode/gh/uv/niri/starship/bat/procs/delta/fd/lazygit/git/apt/dot/dota/y/zoxide/eza/rg），避免 carapace 占位阻止 fish 加载更准的自带补全。

---

## 工具集成

`50-tools.fish` 用 `_cached_init` 函数缓存所有工具的 init 脚本到 `~/.cache/fish/init/`，工具二进制更新时自动重建。避免每次启动 fork 6+ 个子进程。

已集成的工具：

| 工具 | 作用 | 配置位置 |
|---|---|---|
| starship | 提示符 | `~/.config/starship.toml`（matugen 生成 colors） |
| zoxide | 智能 cd（替代 cd） | `cd` 命令已被 zoxide 接管 |
| atuin | 历史搜索（Ctrl-R） | `~/.config/atuin/` |
| carapace | 通用补全兜底 | `CARAPACE_BRIDGES=zsh,fish,bash,inshellisense` |
| uv | Python 包管理 | |
| fnm | Node.js 版本 | |
| mise | 统一版本管理器 | |
| direnv | 项目环境 | |

缓存目录：`~/.cache/fish/init/`。**重建缓存**：`rm -rf ~/.cache/fish/init/`。

---

## Fisher 插件

`fish_plugins` 清单：

| 插件 | 作用 |
|---|---|
| `jorgebucaran/fisher` | 插件管理器 |
| `patrickf1/fzf.fish` | fzf 集成（Ctrl-R/Alt-F/L/S/P/V） |
| `jorgebucaran/autopair.fish` | 自动配对括号引号 |
| `franciscolourenco/done` | 长任务完成通知 |
| `meaningful-ooo/sponge` | 自动清理失败命令的历史记录 |

安装/管理插件：

```fish
fisher install owner/repo      # 安装
fisher list                    # 查看已装
fisher update                  # 更新全部
fisher remove owner/repo       # 卸载
```

---

## 日常维护

### 改完配置后生效

```fish
fishreload        # 等于 exec fish，重启 shell
```

### 编辑配置

| 缩写 | 展开 |
|---|---|
| `fishconf` | `$EDITOR ~/.config/fish/conf.d/` |
| `fishabbr` | `$EDITOR ~/.config/fish/conf.d/20-abbreviations.fish` |

### dotfiles 同步

```fish
dot status                       # 查看哪些配置文件变了
dota home/.config/foo/bar        # dota 是 dot add -f 的简写，路径相对于 ~/dotfiles 仓库根
dot commit -m "msg"
dot push
```

仓库为普通 git 仓库（`~/dotfiles`），`home/` 包经 GNU Stow 部署到 `$HOME`，
跟踪路径统一带 `home/` 前缀。`.gitignore`（位于 `~/dotfiles/.gitignore`）用黑名单策略排除敏感/缓存文件。

---

## 启动性能优化

`50-tools.fish` 的 `_cached_init` 是核心优化：

- 首次启动：fork 6 个子进程生成 init 脚本，缓存到 `~/.cache/fish/init/*.fish`
- 后续启动：检测工具二进制 mtime，没更新就直接 source 缓存
- 工具更新后：自动重建对应缓存

**手动重建**：

```fish
rm -rf ~/.cache/fish/init/        # 下次启动重建所有
```

---

## 故障排查

### Tab 补全不工作 / 慢

```fish
fish-comp-doctor           # 体检
fish-comp-doctor <命令>    # 诊断单个命令
```

常见原因：carapace 占位阻止 fish 加载自带补全。`50-tools.fish` 已对关键命令预加载自带补全覆盖 carapace。

### pager 颜色不对

```fish
# 检查 pager 变量
fish -ic 'set -L | grep fish_pager_color'
```

如果 `35-pager-matugen.fish` 不存在或过期，重新生成：

```fish
# 临时最小生成（不触发其他工具 reload）：
cat > /tmp/matugen-fish-only.toml <<'EOF'
[config]
reload_apps = false
[templates.fish]
input_path = '~/.config/matugen/templates/fish-pager.fish'
output_path = '~/.config/fish/conf.d/35-pager-matugen.fish'
EOF
matugen color hex '#8dcff2' -c /tmp/matugen-fish-only.toml

# 或者完整重跑（会 reload 所有 app）：
matugen image /path/to/current-wallpaper.jpg
```

### 工具 init 缓存损坏

```fish
rm -rf ~/.cache/fish/init/
exec fish
```

### 历史记录异常

sponge 插件会自动清理失败命令。检查配置：

```fish
set -U | grep sponge
```

可临时禁用：`set -U sponge_filters ""`。

### command-not-found 不工作

依赖 `pkgfile`。检查：

```fish
command -q pkgfile; or echo "未安装 pkgfile"
sudo pkgfile --update       # 更新数据库
```

---

## 已知限制

1. **没有 fzf-tab 等价物**：fish 的 pager 是内置 C++ 代码，不像 zsh 可替换 widget。最接近的是 `Shift-Tab`（进入 substring 搜索，不是 fuzzy）。社区在 [fish #12456](https://github.com/fish-shell/fish-shell/issues/12456) 讨论原生支持，截至 2026-07 未实现。

2. **`complete -C` 转义 bug**：影响 DIY fzf 集成（issue #3469），这是鱼团队多年未解的历史问题，不建议自己 hack。

3. **carapace 与自带补全冲突**：carapace 注册后会"占位"。已在 `50-tools.fish` 对关键命令预 source 自带补全解决，新工具可能需要手动 `fish-update-completions <cmd>`。

4. **mise 补全依赖 usage ≥ 4.0**：mise 生成的 usage spec 用了 `effect=` 新语法，
   Arch 仓库的 usage 3.5.5 解析失败（`unsupported cmd prop effect`）。
   已通过 `~/.local/bin/usage` → mise 内置 usage 5.1.0 的 symlink 解决。
   若重装 usage 系统包后补全报错，检查：`~/.local/bin/usage --version` 应为 5.x。

5. **键绑定覆盖**：fish 4.x 在第一个 prompt 时通过 `fish_user_key_bindings` 应用自定义绑定
   （`__fish_config_interactive.fish:100-101`），它在 conf.d 之后执行，因此能覆盖插件绑定。
   注意：**不要用 `bind --erase --all <key>`** —— 实测该语法会擦除所有自定义绑定
   （而非只擦指定键），曾导致 fzf.fish / atuin 的全部绑定失效。

---

## 文件清单速查

### 你最常编辑的

| 文件 | 作用 |
|---|---|
| `conf.d/20-abbreviations.fish` | 加缩写（最常改） |
| `conf.d/25-aliases.fish` | 加别名 |
| `conf.d/40-fzf.fish` | fzf 主题/预览 |
| `conf.d/50-tools.fish` | 加新工具初始化 |
| `functions/fish_user_key_bindings.fish` | 加键绑定（fish 官方覆盖点，conf.d 之后执行） |

### 自动生成勿手改

| 文件 | 生成方式 |
|---|---|
| `conf.d/35-pager-matugen.fish` | matugen 从 `~/.config/matugen/templates/fish-pager.fish` 渲染 |
| `~/.config/starship.toml` | `base.toml` + matugen 生成的 `colors.toml` 拼接 |
| `~/.cache/fish/init/*.fish` | `_cached_init` 缓存的工具 init 脚本 |

### 插件提供的（Fisher 管理）

| 文件 | 插件 |
|---|---|
| `conf.d/autopair.fish` + `functions/_autopair_*.fish` | autopair |
| `conf.d/done.fish` | done |
| `conf.d/fzf.fish` + `functions/_fzf_*.fish` + `functions/fzf_configure_bindings.fish` | fzf.fish |
| `conf.d/sponge.fish` + `functions/_sponge_*.fish` | sponge |
| `functions/fisher.fish` + `completions/fisher.fish` | fisher |
