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
│   ├── zz-bindings-override.fish     最终键绑定覆盖（最后加载）
│   ├── autopair.fish                 ← Fisher 插件
│   ├── done.fish                     ← Fisher 插件
│   ├── fzf.fish                      ← Fisher 插件
│   └── sponge.fish                   ← Fisher 插件
├── completions/                      工具自带补全（40+ 文件，fish-update-completions 生成）
├── functions/                        自定义函数 + 插件函数
└── themes/                           （空，配色由 matugen 动态注入）
```

**加载顺序**：`config.fish` -> `conf.d/` 按文件名字母序 -> 数字优先 `35-` -> `35-pager-matugen.fish` 覆盖 `35-pager.fish` -> `zz-` 最后加载确保覆盖插件。

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

| 按键 | 功能 | 说明 |
|---|---|---|
| `Ctrl-R` | 历史命令搜索 | **被 atuin 接管**（SQLite + 模糊 + 跨机同步） |
| `Ctrl-Alt-F` | 文件搜索 | bat 预览 |
| `Ctrl-Alt-L` | git log 搜索 | |
| `Ctrl-Alt-S` | git status 搜索 | |
| `Ctrl-Alt-P` | 进程搜索 | |
| `Ctrl-V` | 变量搜索 | |

### 5. 其他常用绑定

| 按键 | 功能 |
|---|---|
| `Ctrl-X,Ctrl-E` | 在 $EDITOR 中编辑当前命令行 |
| `Ctrl-L` | 清屏 |
| `Ctrl-C` | 中断当前命令 |
| `Alt-←` / `Alt-→` | 按词移动光标 |
| `Ctrl-←` / `Ctrl-→` | 按 token 移动光标 |
| `Alt-E` / `Alt-V` | 用 $EDITOR 打开命令行 |
| `Alt-S` | 在命令前加 `sudo` |

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
| `dot` | 管理 dotfiles 裸仓库（GIT_DIR=~/.cfg, GIT_WORK_TREE=~） | `dot status` / `dot diff` / `dot push` |
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

pager 颜色映射设计：

| 元素 | Material You token | 含义 |
|---|---|---|
| 选中行背景 | `primary` | 亮色，对比强烈 |
| 选中行前景 | `on_primary` + `--bold` | 专为 primary 背景设计的文字色 |
| 命令前缀 | `primary` | 第一组 |
| 选项前缀 | `tertiary` | 第二组 |
| 文件前缀 | `secondary` | 第三组 |
| 补全文字 | `on_surface` | 主前景色 |
| 描述文字 | `on_surface_variant` | 次要文字色 |
| 搜索匹配 | `secondary` 背景 + `--bold` | 区别于选中行 |

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
dot status                   # 查看哪些配置文件变了
dot add .config/foo/bar      # 跟踪新文件（需先在 ~/.gitignore 白名单加 !path）
dota .config/foo/bar         # dota 是 dot add 的简写，路径相对 $HOME
dot commit -m "msg"
dot push
```

`~/.gitignore` 策略：默认忽略一切，白名单显式 `!path/to/file` 跟踪。

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

---

## 文件清单速查

### 你最常编辑的

| 文件 | 作用 |
|---|---|
| `conf.d/20-abbreviations.fish` | 加缩写（最常改） |
| `conf.d/25-aliases.fish` | 加别名 |
| `conf.d/40-fzf.fish` | fzf 主题/预览 |
| `conf.d/50-tools.fish` | 加新工具初始化 |
| `conf.d/zz-bindings-override.fish` | 加键绑定 |

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
