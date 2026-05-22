# lss 的 Arch dotfiles

这套仓库是我自己的 Arch Linux 配置起点，主要用途有两个：

1. 重装系统后可以快速恢复常用环境。
2. 以后如果别人想复用，也可以直接参考这套配置逐步搭建自己的环境。


// 每次要执行的操作
dot status
dot add .config/niri
dot commit -m "update niri config"
dot push

现在它还是一个“从零慢慢长出来”的仓库，当前先放最基础、最核心的配置，后面会继续补充更多内容。

## 目前的内容

现在这个仓库使用裸仓库方式管理 dotfiles。`dot` 命令会把工作区指向你的 `$HOME`，所以你可以直接管理家目录里的配置文件，比如：

```bash
dot add .config/niri
dot add .zshrc
dot add .config/zsh/aliases.zsh
```

仓库里已经准备好的内容：

- `setup-bare-repo.sh`：初始化裸仓库的脚本。
- `~/.config/zsh/aliases.zsh`：包含 `dot()` 这样的常用别名。
- `README.md`：这个说明文件。

## 怎么用

先进入这个目录并初始化：

```bash
cd ~/dotfiles
./setup-bare-repo.sh
```

然后确保你的 zsh 会加载别名文件。现在我的配置里已经默认会加载 `~/.config/zsh/aliases.zsh`，所以一般重新打开终端就能直接用 `dot`。

初始化以后，建议先把你最核心的配置加进来，例如：

```bash
dot add .zshrc
dot add .config/zsh
dot add .config/niri
dot add .config/kitty
dot add .config/hypr
```

提交一个初始版本：

```bash
dot commit -m "Initial Arch dotfiles"
```

## 以后会继续加什么

这个仓库后面会继续补充更多 Arch 上常用的配置，例如：

- shell 和终端配置
- 窗口管理器配置
- 编辑器配置
- 主题和字体
- 常用工具的设置
- 需要在重装系统后自动恢复的脚本

如果你在别的机器上复用这套配置，建议的方式也是先恢复最基础的 shell 和终端，再慢慢把其他配置补齐。

## 说明

- 这是一个面向个人 Arch 环境的配置仓库。
- 现在内容还不完整，后续会持续补充。
- 如果你新加了某个配置目录，直接用 `dot add` 把它纳入版本控制就行。

