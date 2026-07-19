# Zsh 配置说明

本目录是 Zsh 的配置根目录（`$ZDOTDIR = ~/.config/zsh`），遵循 XDG Base Directory 规范。
通过 Zinit 管理插件，Powerlevel10k 提供提示符，zsh-abbr 提供 fish 风格缩写，
fzf-tab 提供模糊补全，整体面向 Arch Linux + pacman 工具链。

---

## 目录结构

```
~/.config/zsh/
├── .zshrc                # 交互式主入口，按顺序 source 各模块
├── .zshenv               # 非交互式环境变量（所有 zsh 实例都会加载）
├── env.zsh               # 交互式专属环境变量（HISTSIZE、FZF、LS_COLORS...）
├── options.zsh           # setopt / unsetopt 选项
├── plugins.zsh           # Zinit + 全部插件加载
├── completions.zsh       # compinit + 补全 zstyle + fzf-tab 样式
├── abbreviations.zsh     # zsh-abbr 缩写 seed（首次启动自动生成）
├── aliases.zsh           # 传统别名（透明替换 / 安全标志 / 颜色）
├── functions.zsh         # Shell 函数（mkcd / groot / extract / y ...）
├── bindings.zsh          # 键绑定
├── integrations.zsh      # direnv / mise / carapace / zoxide / atuin / cnf
├── p10k.zsh              # Powerlevel10k 主题配置
├── local.zsh             # （可选）本地未跟踪覆盖，不进 git
├── completions/          # 自定义补全脚本（_deno / _fnm / _hermes / _lazygit / _mise）
└── .zcompdump            # compinit 缓存（自动生成）
```

> 通用环境变量（XDG / EDITOR / LANG / PATH / FZF_DEFAULT_*）由
> `~/.config/environment.d/` 通过 systemd 加载，zsh / fish / GUI 共享，
> 不在本目录内重复。

---

## 加载顺序

`.zshrc` 严格按以下顺序加载，**不要随意调换**（存在依赖关系）：

1. **p10k instant prompt** — 必须最先，零延迟提示符
2. `env.zsh` — 历史记录、命名目录、FZF、LS_COLORS
3. `options.zsh` — setopt 标志
4. `plugins.zsh` — Zinit + 全部插件（其中 `zsh-abbr` 同步加载）
5. `completions.zsh` — `compinit` + fzf-tab 样式
6. `abbreviations.zsh` — zsh-abbr 缩写（依赖 abbr 命令存在）
7. `aliases.zsh` — 传统别名
8. `functions.zsh` — Shell 函数
9. `bindings.zsh` — 键绑定
10. `integrations.zsh` — direnv / mise / carapace / zoxide / atuin（必须在 compinit 之后）
11. `p10k.zsh` — 主题配置
12. `local.zsh` — 本地覆盖（如果存在）

---

## 插件清单（Zinit）

| 插件                                | 加载方式 | 用途                              |
| ----------------------------------- | -------- | --------------------------------- |
| `romkatv/powerlevel10k`             | 同步     | 提示符主题（lean 风格 + instant prompt） |
| `olets/zsh-abbr`                    | 同步     | fish 风格缩写                     |
| `zdharma-continuum/fast-syntax-highlighting` | 异步 | 语法高亮                    |
| `zsh-users/zsh-autosuggestions`     | 异步     | 命令自动建议（灰色提示）          |
| `zsh-users/zsh-completions`         | 异步     | 额外补全                          |
| `zsh-users/zsh-history-substring-search` | 异步 | ↑/↓ 按子串搜索历史              |
| `Aloxaf/fzf-tab`                    | 异步     | Tab 补全 fzf 化                   |
| `wfxr/forgit`                       | 异步     | fzf + git 交互（`git log`/`git add` 等） |
| `zinit-annex-as-monitor`            | -        | 监控插件更新                      |
| `zinit-annex-patch-dl`              | -        | 补丁下载                          |

**工具策略**：`fd` / `bat` / `eza` / `rg` / `sd` / `delta` / `hyperfine` / `dust` / `procs` / `btop` / `fzf` 等一律来自 `pacman`，不再用 `zinit ice gh-r` 下载。

---

## 第三方工具集成（integrations.zsh）

| 工具        | 作用                                            |
| ----------- | ----------------------------------------------- |
| `zoxide`    | 智能 cd，通过 `--cmd cd` 接管原生 `cd`          |
| `mise`      | 统一版本管理器（Node/Python/Ruby/Go...）         |
| `direnv`    | 项目级 `.envrc` 自动加载                        |
| `uv`        | Python uv 的 shell 补全（按日缓存）             |
| `atuin`     | 神级历史搜索，接管 `Ctrl+R`（不接管 ↑）         |
| `carapace`  | 多 shell 通用补全引擎（桥接 zsh/fish/bash/inshellisense） |
| `pkgfile`   | command-not-found 时提示安装哪个包              |
| `broot`     | 目录浏览（如果安装）                            |
| `bun`       | bun 补全（如果存在 `~/.bun/_bun`）              |
| `conda`     | Conda/Mamba（如果存在）                         |

---

## 常用键位

### 行编辑
| 按键              | 动作                       |
| ----------------- | -------------------------- |
| `Ctrl+A` / `Ctrl+E` | 行首 / 行尾（emacs 风格） |
| `Ctrl+Right/Left` | 按词前进 / 后退（多终端序列兜底） |
| `Ctrl+W`          | 删除前一个词（emacs 默认）  |
| `Ctrl+U`          | 删到行首（emacs 默认）      |
| `Ctrl+K`          | 删到行尾（emacs 默认）      |
| `Ctrl+Backspace`  | 删除前一个词（多终端序列兜底） |
| `Delete`          | 删除后一个字符              |

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
| `grs`  | `git restore --staged`                |
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
- `dot` -> `GIT_DIR=$HOME/.cfg GIT_WORK_TREE=$HOME git`（dotfiles 裸仓库）
- `dota` -> `dot add` 简写（路径相对于 $HOME，可带前导 ./）

---

## Shell 函数（functions.zsh）

| 函数              | 用途                                              |
| ----------------- | ------------------------------------------------- |
| `mkcd <dir>`      | 创建目录并进入                                    |
| `groot`           | 跳到当前 git 仓库根目录（注意：不叫 `gr`，避免冲突） |
| `port <端口号>`   | 检查端口占用（`sudo lsof`）                        |
| `sysinfo`         | 打印系统信息（OS/内核/Shell/内存/磁盘/包数）       |
| `y [args...]`     | yazi 包装：退出后 cd 到目标目录                    |
| `extract <file>`  | 通用解压（tar.gz/tar.xz/tar.zst/zip/7z/rar/...）   |

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

## 补全（completions.zsh）

- `compinit` 一次 / 24 小时缓存（`~/.cache/zsh/zcompdump`），异步 `zcompile` 加速下次启动
- `matcher-list`：大小写不敏感 + 子串匹配
- `approximate`：允许 2 个字符的模糊补全
- 分组显示 + 彩色标题（cyan / purple / red / yellow）
- **fzf-tab**：Tab 补全全部 fzf 化，按 `/` 进入子目录，回车直接执行
- 预览：
  - `cd` / `z` → `eza` 树状预览
  - `cat` / `nvim` → `bat` 内容预览
  - `git add/diff/restore` → `git diff` 预览
  - `git checkout` → `git log` 预览
  - `kill` → `procs` 进程预览
  - `systemctl` → `systemctl status` 预览
  - `man` → man 页前 50 行预览

### 自定义补全脚本
`completions/` 目录下：
- `_deno` — Deno
- `_fnm` — fnm
- `_hermes` — Hermes
- `_lazygit` — lazygit
- `_mise` — mise

（fpath 中 `completions/` 排在最前，可覆盖 carapace 桥接的同名补全）

---

## Powerlevel10k 主题

- 风格：**lean**（无背景填充，简洁）
- 字体：nerdfont-v3 + powerline
- 单行提示符，24h 时间，紧凑布局，多图标
- `instant_prompt=verbose`：首次启动会显示加载日志
- 重新生成配置：`p10k configure`

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
| 重新生成 P10K 主题           | `p10k configure`                              |
| 备份 dotfiles 状态          | `dot stash` 或 `dot tag backup-$(date +%F)`   |
| 更新 pkglist                | `bash ~/.config/dotfiles/update-pkglist.sh`   |
| 清理 compinit 缓存           | 删除 `~/.cache/zsh/zcompdump*` 后 `exec zsh`   |

---

## 本地覆盖

如需本地、不进 git 的私有配置，新建 `~/.config/zsh/local.zsh`，会在最后被自动 source。
