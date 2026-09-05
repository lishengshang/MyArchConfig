#!/usr/bin/env python3
"""P2-4 静态检查：仓库内 TOML 与 JSONC 配置文件语法校验。

设计约束（2026-09-05，P3-14）：
- TOML 目标动态发现（git ls-files '*.toml'），但排除 matugen/templates/——
  那些是含 {{ }} 占位符的模板，必须先经 matugen 渲染才是合法 TOML。
- JSONC 目标用显式清单：只有不含 matugen 占位符的纯配置才可解析。
  新增 JSONC 文件时在此登记，不要动态发现。
- 本脚本同时用于本地验证与 CI（.github/workflows/lint.yml），零第三方依赖
  （tomllib 需要 Python >= 3.11）。
"""

import json
import subprocess
import sys
import tomllib

# matugen 模板目录：{{ }} 占位符未渲染，不是合法 TOML，跳过
TOML_EXCLUDES = ("home/.config/matugen/templates/",)

# 显式 JSONC 清单：已确认不含 matugen 占位符的纯配置文件
JSONC_FILES = (
    "home/.config/waybar/config.jsonc",
    "home/.config/waybar/modules.jsonc",
    "home/.config/Code/User/settings.base.json",
)


def strip_jsonc(text: str) -> str:
    """剔除 JSONC 的 // 与 /* */ 注释（字符串字面量感知的简单状态机）。"""
    out = []
    i, n = 0, len(text)
    in_string = False
    while i < n:
        ch = text[i]
        if in_string:
            out.append(ch)
            if ch == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if ch == '"':
                in_string = False
            i += 1
        elif ch == '"':
            in_string = True
            out.append(ch)
            i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "/":
            while i < n and text[i] != "\n":
                i += 1
        elif ch == "/" and i + 1 < n and text[i + 1] == "*":
            i += 2
            while i + 1 < n and not (text[i] == "*" and text[i + 1] == "/"):
                i += 1
            i += 2
        else:
            out.append(ch)
            i += 1
    return "".join(out)


def tracked_toml_files() -> list[str]:
    files = subprocess.run(
        ["git", "ls-files", "*.toml"], check=True, capture_output=True, text=True
    ).stdout.splitlines()
    return sorted(f for f in files if not f.startswith(TOML_EXCLUDES))


def main() -> int:
    failed = False

    toml_files = tracked_toml_files()
    if not toml_files:
        print("TOML: 未发现目标文件（请在仓库根运行）")
        return 1
    for path in toml_files:
        try:
            with open(path, "rb") as fh:
                tomllib.load(fh)
            print(f"  TOML ok: {path}")
        except (tomllib.TOMLDecodeError, OSError) as exc:
            print(f"  TOML FAIL: {path}: {exc}")
            failed = True

    for path in JSONC_FILES:
        try:
            with open(path, encoding="utf-8") as fh:
                json.loads(strip_jsonc(fh.read()))
            print(f"  JSONC ok: {path}")
        except (json.JSONDecodeError, OSError) as exc:
            print(f"  JSONC FAIL: {path}: {exc}")
            failed = True

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
