# Zsh 配置说明

本目录是 Zsh 的配置根目录（`$ZDOTDIR = ~/.config/zsh`），遵循 XDG Base Directory 规范。
通过 Zinit 管理插件，Starship 提供提示符，zsh-abbr 提供 fish 风格缩写，
fzf-tab 提供模糊补全，整体面向 Arch Linux + pacman 工具链。

---

## 目录结构

```
~/.config/zsh/
├── .zshrc                  # 交互式主入口，按顺序 source 各模块
├── .zshenv                 # 非交互式环境变量（所有 zsh 实例都会加载）
├── env.zsh                 # 交互式专属环境变量（HISTSIZE、FZF、LS_COLORS...）
├── options.zsh             # setopt / unsetopt 选项
├── plugins.zsh             # Zinit + 全部插件加载
├── completions.zsh         # 补全子系统入口（fpath 归位 + 指纹校验 + compinit + 子模块）
├── completion-styles.zsh   # compinit zstyle：菜单、匹配、颜色、分组
├── completion-fzf-tab.zsh  # fzf-tab 样式与预览
├── abbreviations.zsh       # zsh-abbr 缩写 seed（首次启动自动生成）
├── aliases.zsh             # 传统别名（透明替换 / 安全标志 / 颜色）
├── functions.zsh          # Shell 函数（mkcd / groot / y ...）
├── bindings.zsh           # 键绑定
├── integrations.zsh       # starship / direnv / mise / carapace / zoxide / atuin / cnf
├── local.zsh              # （可选）本地未跟踪覆盖，不进 git
└── completions/           # 手写补全脚本（fpath 优先位置）
```

> 通用环境变量（XDG / EDITOR / LANG / PATH / FZF_DEFAULT_*）由
> `~/.config/environment.d/` 通过 systemd 加载，zsh / fish / GUI 共享，
> 不在本目录内重复。

---

## 加载顺序

`.zshrc` 严格按以下顺序加载，**不要随意调换**（存在依赖关系）：

1. `env.zsh` - 历史记录、命名目录、FZF、LS_COLORS
2. `options.zsh` - setopt 标志
3. `plugins.zsh` - Zinit + 全部插件（其中 `zsh-abbr` 同步加载）
4. `completions.zsh` - 补全子系统入口（顺序内部 source 子模块：
   `compinit` -> `completion-styles.zsh` -> `completion-fzf-tab.zsh`）
5. `abbreviations.zsh` - zsh-abbr 缩写（依赖 abbr 命令存在）
6. `aliases.zsh` - 传统别名
7. `functions.zsh` - Shell 函数
8. `bindings.zsh` - 键绑定
9. `integrations.zsh` - starship / direnv / mise / carapace / zoxide / atuin（starship 必须最后加载，覆盖 PROMPT）
10. `local.zsh` - 本地覆盖（如果存在）

---

## 插件清单（Zinit）

| 插件                                | 加载方式 | 用途                              |
| ----------------------------------- | -------- | --------------------------------- |
| `olets/zsh-abbr`                    | 同步     | fish 风格缩写                     |
| `zdharma-continuum/fast-syntax-highlighting` | 异步 | 语法高亮                    |
| `zsh-users/zsh-autosuggestions`     | 异步     | 命令自动建议（灰色提示）          |
| `zsh-users/zsh-completions`         | 异步     | 额外补全                          |
| `zsh-users/zsh-history-substring-search` | 异步 | ↑/↓ 按子串搜索历史              |
| `Aloxaf/fzf-tab`                    | 异步     | Tab 补全 fzf 化                   |
| `wfxr/forgit`                       | 异步     | fzf + git 交互（`git log`/`git add` 等） |
| `zinit-annex-as-monitor`            | -        | 监控插件更新                      |
| `zinit-annex-patch-dl`              | -        | 补丁下载                          |

**提示符**：由 `starship`（Rust，跨 shell）提供，配置在 `~/.config/starship.toml`。

**工具策略**：`fd` / `bat` / `eza` / `rg` / `sd` / `delta` / `hyperfine` / `dust` / `procs` / `btop` / `fzf` 等一律来自 `pacman`，不再用 `zinit ice gh-r` 下载。

---

## 第三方工具集成（integrations.zsh）

**init 缓存策略**（与 fish 的 `_cached_init` 对等）：所有 `tool init zsh` 的输出
缓存到 `~/.cache/zsh/init/<name>.zsh`，工具二进制更新（mtime 变化）时自动重建，
避免每次启动 fork 子进程。手动重建：`rm -rf ~/.cache/zsh/init/`。

| 工具        | 作用                                            |
| ----------- | ----------------------------------------------- |
| `starship`  | 提示符主题（跨 shell，Rust 实现，配置在 `~/.config/starship.toml`） |
| `zoxide`    | 智能 cd，通过 `--cmd cd` 接管原生 `cd`          |
| `mise`      | 统一版本管理器（Node/Python/Ruby/Go...）；shims 模式（`activate --shims`，零启动 hook 开销；如需 .mise.toml 项目级 env 自动重载，改用 `activate zsh`） |
| `direnv`    | 项目级 `.envrc` 自动加载                        |
| `atuin`     | 神级历史搜索，接管 `Ctrl+R`（不接管 ↑）         |
| `carapace`  | 多 shell 通用补全引擎（桥接 zsh/fish/bash/inshellisense，统一提供 opencode/uv/gh/deno 等工具补全） |
| `pkgfile`   | command-not-found 时提示安装哪个包              |
| `broot`     | 目录浏览（如果安装）                            |
| `bun`       | bun 补全（如果存在 `~/.bun/_bun`）              |
| `conda`     | Conda/Mamba（如果存在，mise 优先）              |

---

## 常用键位

### 行编辑
| 按键              | 动作                       |
| ----------------- | -------------------------- |
| `Ctrl+A` / `Ctrl+E` | 行首 / 行尾（emacs 风格） |
| `Ctrl+B` / `Ctrl+F` | 后退 / 前进一个字符 |
| `Alt+B` / `Alt+F` / `Ctrl+Left/Right` | 按词后退 / 前进（多终端序列兜底） |
| `Backspace` (`^H` / `^?`) | 删除前一个字符 |
| `Delete` (`^[[3~`) | 删除后一个字符 |
| `Ctrl+D` | 删除字符或列出补全 |
| `Ctrl+W` / `Ctrl+Backspace` / `Alt+Backspace` | 删除前一个词 |
| `Ctrl+U` | 删除整行（kill-whole-line） |
| `Ctrl+K` | 删除到行尾（emacs 默认） |
| `Alt+.` / `Alt+_` | 插入上一命令的最后参数（insert-last-word，兼容 readline） |

> `Ctrl+Right/Left` 和 `Ctrl+Backspace` 在不同终端模拟器下发的 escape sequence 不同，
> bindings.zsh 中用 `_bind_keys` 尝试多个已知序列。若仍不生效，执行 `zkbd` 生成终端专属映射。

### 补全与历史
| 按键            | 动作                                            |
| --------------- | ----------------------------------------------- |
| `Tab`           | 补全（fzf-tab 接管，模糊匹配）                 |
| `Shift+Tab`     | 反向补全                                        |
| `Ctrl+R`        | Atuin 历史搜索                                  |
| `↑` / `↓`       | 按前缀子串搜索历史（history-substring-search）  |
| `Ctrl+P` / `Ctrl+N` | 同 ↑/↓                                      |

### 自动建议
| 按键              | 动作             |
| ----------------- | ---------------- |
| `Ctrl+Space`      | 接受整条建议      |
| `Alt+Enter`       | 接受整条建议（备用）|
| `->` (Right)      | 逐字接受建议（partial accept，zsh-autosuggestions 默认行为）|

> 缩写展开：输入缩写后按**空格**展开（`abbr-expand-and-insert`），按**回车**展开并执行
> （`abbr-expand-and-accept`）。`Ctrl+Space` 优先接受自动建议（非空格插入）。

### fzf
| 按键        | 动作                                   |
| ----------- | -------------------------------------- |
| `Ctrl+T`    | 模糊搜索文件并插入到命令行（bat 预览） |
| `Alt+C`     | 模糊搜索目录并 cd（eza 预览）          |
| `Ctrl+R`    | 历史搜索（被 Atuin 接管）              |

### 其他
| 按键            | 动作                          |
| --------------- | ----------------------------- |
| `Ctrl+X Ctrl+E` | 在 `$EDITOR` 中编辑当前命令行 |
| `Ctrl+L`        | 清屏                          |
| `Alt+<` / `Alt+>` | 跳到历史首 / 末              |

---

## 完整 bindkey 列表

下面是当前 shell 所有有效键绑定，已转成可读的 `Ctrl+E` / `Alt+E` 写法，并附上中文说明：

| 按键 | 作用 |
| --- | --- |
| `Ctrl+Space` | 接受自动建议 |
| `Ctrl+A` | 光标移到行首 |
| `Ctrl+B` | 光标左移一个字符 |
| `Ctrl+D` | 删除字符或列出补全 |
| `Ctrl+E` | 光标移到行尾 |
| `Ctrl+F` | 光标右移一个字符 |
| `Ctrl+G` | 取消当前输入 |
| `Backspace` | 删除前一个字符 |
| `Tab` | fzf-tab 补全 |
| `Enter` | 执行当前命令 |
| `Ctrl+K` | 删除到行尾 |
| `Ctrl+L` | 清屏 |
| `Ctrl+N` | 按子串搜索下一条历史 |
| `Ctrl+O` | 执行当前命令并取出下一条历史 |
| `Ctrl+P` | 按子串搜索上一条历史 |
| `Ctrl+Q` | 暂存当前行（push-line） |
| `Ctrl+R` | Atuin 历史搜索 |
| `Ctrl+S` | 向前增量搜索历史 |
| `Ctrl+T` | fzf 文件选择 |
| `Ctrl+U` | 删除整行 |
| `Ctrl+V` | 引用插入 |
| `Ctrl+W` | 删除前一个词 |
| `Ctrl+X Ctrl+B` | 匹配括号 |
| `Ctrl+X Ctrl+E` | 在编辑器中编辑命令行 |
| `Ctrl+X Ctrl+F` | 查找下一个字符 |
| `Ctrl+X Ctrl+J` | 合并行 |
| `Ctrl+X Ctrl+K` | 删除缓冲区 |
| `Ctrl+X Ctrl+N` | 推断下一条历史 |
| `Ctrl+X Ctrl+O` | 覆盖模式 |
| `Ctrl+X Ctrl+U` / `Ctrl+X u` | 撤销 |
| `Ctrl+X Ctrl+V` | 进入 vi 命令模式 |
| `Ctrl+X Ctrl+X` | 交换光标与标记 |
| `Ctrl+X *` | 展开单词 |
| `Ctrl+X .` | fzf-tab 调试 |
| `Ctrl+X =` | 显示光标位置 |
| `Ctrl+X G` / `Ctrl+X g` | 列出展开 |
| `Ctrl+X r` | 向后增量搜索历史 |
| `Ctrl+X s` | 向前增量搜索历史 |
| `Ctrl+Y` | 粘贴 |
| `Ctrl+_` | 撤销 |
| `Ctrl+←` / `Ctrl+→` | 后退 / 前进一个词（多终端序列兜底） |
| `Alt+←` / `Alt+→` | 后退 / 前进一个词 |
| `Delete` | 删除后一个字符 |
| `Ctrl+Delete` | 删除前一个词（多终端兜底） |
| `Shift+Tab` | fzf-tab 反向补全 |
| `Alt+Space` / `Alt+!` | 展开历史 |
| `Alt+Backspace` | 删除前一个词 |
| `Alt+Enter` | 接受自动建议 |
| `Alt+"` | 引用选中区域 |
| `Alt+$` / `Alt+S` | 拼写检查 |
| `Alt+'` | 引用整行 |
| `Alt+-` | 输入负参数 |
| `Alt+.` / `Alt+_` | 插入上一命令的最后一个参数 |
| `Alt+0` ~ `Alt+9` | 输入数字参数 |
| `Alt+<` / `Alt+>` | 跳到历史开头 / 末尾 |
| `Alt+?` | 查看命令路径 |
| `Alt+A` / `Alt+a` | 接受并保留 |
| `Alt+B` / `Alt+b` | 后退一个词 |
| `Alt+Shift+C` | 单词首字母大写 |
| `Alt+C` / `Alt+c` | fzf 目录选择 |
| `Alt+D` / `Alt+d` | 删除后一个词 |
| `Alt+F` / `Alt+f` | 前进一个词 |
| `Alt+G` / `Alt+g` | 获取行 |
| `Alt+H` / `Alt+h` | 查看命令帮助 |
| `Alt+L` / `Alt+l` | 单词转小写 |
| `Alt+N` / `Alt+n` | 向前搜索历史 |
| `Alt+P` / `Alt+p` | 向后搜索历史 |
| `Alt+Q` / `Alt+q` | 暂存当前行 |
| `Alt+T` / `Alt+t` | 交换两个词 |
| `Alt+U` / `Alt+u` | 单词转大写 |
| `Alt+W` / `Alt+w` | 复制区域 |
| `Alt+X` | 执行命名命令 |
| `Alt+Y` / `Alt+y` | 轮换粘贴 |
| `Alt+Z` / `Alt+z` | 执行上一个命名命令 |
| <code>Alt+&#124;</code> | 跳到指定列 |
| `Alt+Ctrl+D` | 列出补全候选项 |
| `Alt+Ctrl+G` | 取消当前输入 |
| `Alt+Ctrl+L` | 清屏 |
| `Alt+Ctrl+_` | 复制前一个词 |
| `↑` / `↓` / `←` / `→` | 移动光标；上下同时按子串搜索历史 |
| `?` | Atuin AI `?` 快捷 |

> 可打印字符（`a-z`、`0-9`、标点等）默认都是 `self-insert`，即正常输入文字；`\M-^@`-`\M-^?` 等 Meta 字符序列同理，未单独列出。

---

## 命名目录（hash -d）

可直接 `cd ~name`，提示符里也显示短名：

| 短名    | 路径                |
| ------- | ------------------- |
| `~code` | `~/Code`            |
| `~docs` | `~/Documents`       |
| `~dl`   | `~/Downloads`       |
| `~cfg`  | `~/.config`         |
| `~zsh`  | `~/.config/zsh`     |

---

## 缩写（zsh-abbr）

**用法**：输入缩写后按空格自动展开为完整命令（类似 fish abbr）。

- 增：`abbr add foo=bar`
- 删：`abbr erase foo`
- 列：`abbr list-abbreviations`
- 重新生成默认集：`abbr-seed`

存储位置：`~/.config/zsh-abbr/user-abbreviations`（启动时自动加载，零运行时开销）。

### 常用缩写一览

#### Git
| 缩写   | 展开                                  |
| ------ | ------------------------------------- |
| `g`    | `git`                                 |
| `gs`   | `git status`                          |
| `gss`  | `git status -s`                       |
| `ga`   | `git add`                             |
| `gaa`  | `git add --all`                       |
| `gap`  | `git add -p`                          |
| `gc`   | `git commit`                          |
| `gcm`  | `git commit -m`                       |
| `gca`  | `git commit --amend`                  |
| `gcan` | `git commit --amend --no-edit`        |
| `gp`   | `git push`                            |
| `gpf`  | `git push --force-with-lease`         |
| `gpl`  | `git pull`                            |
| `gf`   | `git fetch`                           |
| `gl`   | `git log --oneline --graph --decorate` |
| `gla`  | `git log ... --all`                   |
| `gd`   | `git diff`                            |
| `gds`  | `git diff --staged`                   |
| `gb`   | `git branch`                          |
| `gco`  | `git checkout`                        |
| `gcb`  | `git checkout -b`                     |
| `gsw`  | `git switch`                          |
| `gst`  | `git stash`                           |
| `gstp` | `git stash pop`                        |
| `gr`   | `git restore`                          |
| `grs`  | `git restore --staged`                 |
| `gm`   | `git merge`                           |
| `grb`  | `git rebase`                          |
| `grbi` | `git rebase -i`                       |
| `lg`   | `lazygit`                             |

#### Docker
| 缩写    | 展开             |
| ------- | ---------------- |
| `d`     | `docker`         |
| `dc`    | `docker compose` |
| `dps`   | `docker ps ...`（格式化表格） |
| `dpsa`  | `docker ps -a`   |
| `di`    | `docker images`  |
| `dex`   | `docker exec -it` |
| `dlog`  | `docker logs -f` |
| `dstop` | 停止所有容器     |
| `dclean`| `docker system prune -af` |

#### 现代化列表
| 缩写   | 展开                                                   |
| ------ | ------------------------------------------------------ |
| `ll`   | `eza -l --icons --group-directories-first --git ...`   |
| `la`   | `eza -la --icons --group-directories-first --git`      |
| `lla`  | `eza -la ... --time-style=long-iso`                    |
| `tree` | `eza --tree --icons --level=2`                         |
| `treea`| `eza --tree --icons --level=3 -a`                     |

#### 编辑器
| 缩写  | 展开             |
| ----- | ---------------- |
| `v`   | `nvim`           |
| `vim` | `nvim`           |
| `sv`  | `sudo -E nvim`   |

#### 目录跳转
| 缩写   | 展开         |
| ------ | ------------ |
| `..`   | `cd ..`      |
| `...`  | `cd ../..`   |
| `....` | `cd ../../..`|

#### Arch 包管理
| 缩写      | 展开                              |
| --------- | --------------------------------- |
| `pacup`   | `sudo pacman -Syu`                |
| `pacss`   | `pacman -Ss`                      |
| `pacin`   | `sudo pacman -S`                  |
| `pacrm`   | `sudo pacman -Rns`                |
| `pacclean`| `sudo pacman -Sc`                 |
| `paclist` | `pacman -Qq \| fzf --preview ...` |
| `yayup`   | `yay -Syu`                        |
| `paruup`  | `paru -Syu`                       |

#### 网络
| 缩写   | 展开                              |
| ------ | --------------------------------- |
| `myip` | `curl -s https://ipinfo.io/json \| jq` |
| `ports`| `ss -tulanp`                      |
| `ping` | `ping -c 5`                       |

#### Python
| 缩写       | 展开                          |
| ---------- | ----------------------------- |
| `py`       | `python`                      |
| `py3`      | `python3`                     |
| `venv`     | `python -m venv .venv`        |
| `activate` | `source .venv/bin/activate`   |

#### 配置编辑
| 缩写        | 展开                                   |
| ----------- | -------------------------------------- |
| `zshrc`     | `$EDITOR ~/.config/zsh/.zshrc`         |
| `zshreload` | `exec zsh`                             |
| `aliasrc`   | `$EDITOR ~/.config/zsh/aliases.zsh`    |
| `abbrc`     | `$EDITOR ~/.config/zsh/abbreviations.zsh` |
| `envrc`     | `$EDITOR ~/.config/zsh/env.zsh`        |

#### 系统信息 / 通用
| 缩写   | 展开                          |
| ------ | ------------- |
| `free` | `free -h`      |
| `duh`  | `du -sh`       |
| `dfh`  | `df -h`        |
| `path` | `echo $PATH \| tr ":" "\n"` |
| `c`    | `clear`        |
| `q`    | `exit`         |
| `h`    | `history \| tail -50` |

---

## 传统别名（aliases.zsh）

### 透明替换（有则替换，无则回退原命令）
- `ls` → `eza --icons --group-directories-first`
- `cat` → `bat --style=plain --paging=never`
- `grep` → `rg --smart-case`
- `du` → `dust`
- `df` → `duf`
- `ps` → `procs`
- `top` → `btop`
- `cd` → `zoxide`（在 integrations.zsh 中通过 `--cmd cd` 接管）

### 安全标志（强制）
- `rm` → `rm -I`（删除前确认）
- `cp` → `cp -iv`
- `mv` → `mv -iv`
- `mkdir` → `mkdir -pv`

### 颜色
- `ip` → `ip --color=auto`
- `diff` → `diff --color=auto`

### 杂项
- `weather` → `curl -s "wttr.in/Wuhan?F&lang=zh"`
- `ds` → `dirs -v`
- `1`..`9` → `cd +1`..`cd +9`（目录栈快速跳转）
- `dot` -> `git -C ~/dotfiles`（dotfiles 仓库）
- `dota` -> `dot add -f` 简写（路径相对于 ~/dotfiles 仓库根）

---

## Shell 函数（functions.zsh）

| 函数              | 用途                                              |
| ----------------- | ------------------------------------------------- |
| `mkcd <dir>`      | 创建目录并进入                                    |
| `groot`           | 跳到当前 git 仓库根目录                          |
| `port <端口号>`   | 检查端口占用（`sudo lsof`）                        |
| `y [args...]`     | yazi 包装：退出后 cd 到目标目录                    |

---

## 选项（options.zsh）关键设置

- **目录导航**：`AUTO_CD`、`AUTO_PUSHD`、`PUSHD_IGNORE_DUPS`、`PUSHD_MINUS`、`PUSHD_SILENT`
- **Globbing**：`EXTENDED_GLOB`、`GLOB_DOTS`、`NUMERIC_GLOB_SORT`，关闭 `NOMATCH`/`CASE_GLOB`
- **History**：`SHARE_HISTORY`、`HIST_IGNORE_ALL_DUPS`、`HIST_IGNORE_SPACE`、`HIST_VERIFY`、`HIST_FCNTL_LOCK`
- **任务**：`NOTIFY`、`CHECK_JOBS`，关闭 `BG_NICE`/`HUP`
- **体验**：`INTERACTIVE_COMMENTS`、`RC_QUOTES`，关闭 `FLOW_CONTROL`/`BEEP`
- **管道**：`PIPE_FAIL`
- **补全**：`AUTO_MENU`、`AUTO_LIST`、`COMPLETE_IN_WORD`、`ALWAYS_TO_END`
- **错误**：`NO_CLOBBER`（`>` 不覆盖，用 `>|` 强制）、`CORRECT`（命令名纠错）
- `WORDCHARS` 去掉 `/`，使 `Ctrl+W` 按路径段删除

### History
- `HISTSIZE=100000`、`SAVEHIST=100000`
- `HISTFILE=$XDG_STATE_HOME/zsh/history`（`~/.local/state/zsh/history`）
- `REPORTTIME=5`：命令耗时超过 5 秒自动报告
- `SPROMPT`：纠错提示格式

---

## 补全（completions.zsh 子系统）

补全逻辑拆为 3 个文件，由 `completions.zsh` 入口编排：

| 文件                      | 职责                                                                              |
| ------------------------- | --------------------------------------------------------------------------------- |
| `completions.zsh`         | 入口：fpath 归位、缓存目录、fpath 指纹校验、`zmodload zsh/complist`、compinit、source 子模块 |
| `completion-styles.zsh`   | `compinit` zstyle：补全器链、菜单、匹配、颜色、分组、模糊纠错                    |
| `completion-fzf-tab.zsh`  | fzf-tab 样式与按主题分组的预览                                                    |

外部工具（opencode/uv/gh/deno/...）的补全由 carapace 桥接统一提供，无需为每个工具维护生成脚本。

### compinit

- 一次 / 24 小时缓存（`~/.cache/zsh/zcompdump`），命中跳过 insecure-dir 检查
- 异步 `zcompile` dump 为 `.zwc` 字节码，下次启动 mmap 加载 ~5x 快
- 缓存目录变量 `ZSH_COMP_CACHE_DIR`（dump + zstyle cache + 指纹 marker 共用）
- **fpath 指纹校验**：`${ZSH_VERSION}|${(j/:/)fpath}` 写入 `~/.cache/zsh/fingerprint`，启动时比对，不一致则删除 dump 强制重建（应对 zsh 升级 / fpath 变化）

### 补全行为（completion-styles.zsh）

- `completer` 链：`_complete` → `_match` → `_approximate`（逐级回退）
- `matcher-list`：大小写不敏感 + 子串匹配
- `approximate`：允许 2 字符模糊补全（数值化）
- 分组显示 + 彩色标题（cyan / purple / red / yellow）
- 进程补全：`kill` 时按 pid 着色

### fzf-tab（completion-fzf-tab.zsh）

Tab 补全全部 fzf 化：按 `/` 进入子目录，回车接受补全并加空格（不直接执行）。
按主题分组的预览：

| 主题             | 命令                                          | 预览                              |
| ---------------- | --------------------------------------------- | --------------------------------- |
| 目录             | `cd` / `__zoxide_z` / `ls`                    | `eza -1 --icons`                  |
| 文件             | `cat` / `nvim`                                | `bat --style=numbers`             |
| Git              | `git add/diff/restore/show/stash`             | `git diff`                        |
|                  | `git checkout`                                | `git log --oneline --graph`       |
|                  | `git log`                                    | `git log --oneline --graph`       |
| 进程             | `kill`                                        | `procs --pid=` / `ps -p`          |
| Systemd          | `systemctl-*`                                 | `SYSTEMD_COLORS=1 systemctl status` |
| Man              | `man`                                         | `man $word | head -50`            |
| 环境变量         | `export` / `unset` / `expand` 等               | `echo ${(P)word}`                 |

### 自定义补全脚本

如需为某个命令添加手写补全，把 `_cmdname` 文件放入 `~/.config/zsh/completions/`，该目录在 fpath 中优先级最高，会覆盖 carapace 桥接的同名补全。compinit 会通过 fpath 自动加载。

---

## Starship 提示符

- 跨 shell（zsh/fish/bash）通用，Rust 实现，配置在 `~/.config/starship.toml`
- 暖色调 palette，单行提示符 + 时间戳
- 在 `integrations.zsh` 末尾通过 `eval "$(starship init zsh)"` 加载，必须最后加载以覆盖 PROMPT
- 配置修改后 `exec zsh` 即可生效

---

## 常见操作

| 任务                         | 命令                                           |
| ---------------------------- | ---------------------------------------------- |
| 重载配置                     | `zshreload`（即 `exec zsh`）                   |
| 编辑主配置                   | `zshrc`                                        |
| 编辑缩写                     | `abbrc`                                        |
| 添加缩写                     | `abbr add foo=bar`                             |
| 重新生成默认缩写集           | `abbr-seed`                                    |
| 更新所有 Zinit 插件          | `zinit update --all`                           |
| 编辑提示符主题               | `$EDITOR ~/.config/starship.toml`              |
| 备份 dotfiles 状态          | `dot stash` 或 `dot tag backup-$(date +%F)`   |
| 更新 pkglist                | `bash ~/dotfiles/update-pkglist.sh`           |
| 清理 compinit 缓存           | 删除 `~/.cache/zsh/zcompdump*` 后 `exec zsh`   |
| 添加手写补全                 | 把 `_cmdname` 放入 `~/.config/zsh/completions/`，重启 shell 自动加载 |

---

## 本地覆盖

如需本地、不进 git 的私有配置，新建 `~/.config/zsh/local.zsh`，会在最后被自动 source。
