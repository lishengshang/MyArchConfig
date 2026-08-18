# 多 Agent 协同维护规范

本仓库是 Linux dotfiles。多个来自不同平台的 Agent 可能并行工作（例如 IDE Agent、命令行 Agent、Web Agent 或其他自动化平台），请优先保证现有用户配置不被破坏。

## 开始工作前

```bash
git status --short
git diff --stat
```

必须先确认当前工作区已有修改。不得执行以下命令清理工作区：

```bash
git reset --hard
git clean -fd
git checkout -- .
```

除非仓库负责人明确要求，否则不要还原其他人的修改。

## 跨平台协作协议

本仓库不假设所有 Agent 使用同一个平台、同一个会话或同一个工作目录。Git 和 `MAINTENANCE_PLAN.md` 是唯一的协作事实来源。

认领任务时，在任务状态后注明平台和 Agent 标识，例如：

```markdown
- `[>]` P0-1 修复 CI 扫描范围 — Owner: GitHub Copilot / ci-agent-01
```

不同平台的 Agent 不要同时修改同一组文件。修改范围有重叠时，后来的 Agent 必须先停下并在任务中标记 `[?]`，等待仓库负责人分配范围。

如果多个平台共享同一个工作目录：

- 不要使用 `git reset --hard`、`git clean` 或批量 checkout；
- 修改前后都执行 `git status --short` 和 `git diff --name-only`；
- 不要把其他平台刚产生的修改当成自己的修改；
- 不要在没有确认的情况下提交、rebase、push 或启用自动提交 timer。

如果不同平台使用各自的 clone 或分支：

- 使用唯一的任务 ID 和分支/提交说明；
- 合并由仓库负责人完成；
- 合并后由负责人统一更新任务状态和删除线；
- 任务状态中的 Agent 名称应包含“平台 / Agent ID”。

每个平台都应在最终报告中给出任务 ID、修改文件、验证命令和剩余风险，不能依赖另一个平台的上下文记忆。

## 任务认领

所有维护任务统一记录在 [`MAINTENANCE_PLAN.md`](MAINTENANCE_PLAN.md)：

- 开始：将 `[ ]` 改为 `[>]`
- 完成：将整行改为 `~~[x] ...~~`
- 阻塞：改为 `[?]`，写清楚需要谁决定什么

完成项必须保留删除线，不能删除历史任务记录。例如：

```markdown
~~[x] 修复截图脚本语法~~ — Agent: GitHub Copilot / agent-a, 日期: 2026-08-19；验证: `bash -n ...`
```

## 修改原则

1. 只修改认领任务涉及的文件。
2. 不要把生成文件、缓存、token、`.env` 或机器私有数据加入 Git。
3. 不要擅自启用自动提交或自动 push。
4. 脚本修改后运行对应的语法检查。
5. Shell、Fish、Zsh、Python 不要混用解释器检查。
6. 对 systemd、Niri、Wayland 配置修改后，尽量运行本机可用的 validate/verify 命令。
7. 如果发现超出任务范围的问题，写入维护计划的“已知但暂不处理的问题”，不要顺手扩大改动范围。

## 完成报告格式

每个 Agent 完成任务时，应在最终回复中说明：

```text
任务：P0-x
修改文件：...
验证：...
结果：通过/阻塞
剩余风险：...
```

除非负责人要求，Agent 不需要自行 commit；如果需要 commit，使用单一、清晰、可回滚的 commit。
