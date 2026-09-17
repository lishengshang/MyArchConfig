#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""niri 边缘点击切换窗口：屏幕左右边缘各一条 8px 热区，左键点击切换相邻列。

行为：点左边缘 = focus-column-left，点右边缘 = focus-column-right（等同 Mod+← / Mod+→）。

为什么这么实现：
- niri 的真全屏窗口必定铺满整屏、且忽略 layout 的 struts，配置层面无法把全屏窗口
  "改小"；而按官方文档，只有 overlay 层的 layer-shell 表面能盖在全屏窗口之上，所以把
  热区放在 overlay 层，全屏（视频 / 浏览器 / 游戏）下照样可点，不需要改窗口尺寸。
- niri 会把 overlay 表面放进"顶栏之下的可用区"，热区自动避开 waybar，不必硬编码栏高。
- 热区宽度与 layout.kdl 的 struts 一致（左右各 8px）：平铺 / 最大化列不会盖住热区，
  点边缘绝不会误触点中窗口内容。改宽度时两处要同步（STRIP_WIDTH 与 layout.kdl）。
- 只有聚焦窗口确实存在相邻列时才显示对应热区，否则隐藏该热区让点击穿透给应用
  （例如单窗口全屏时，屏幕边缘的点击仍然归应用）；总览打开时热区全部隐藏。

用法：
    niri-edge-switch.py                                # 前台运行，Ctrl+C 退出
    systemctl --user start niri-edge-switch.service    # systemd 托管（同名 unit）

依赖：python-gobject、gtk4、gtk4-layer-shell、niri。
"""

import json
import os
import shutil
import subprocess
import sys
import threading
import time

# 热区宽度（逻辑像素）。必须与 ~/.config/niri/layout.kdl 的 struts left/right 一致。
STRIP_WIDTH = 8
NAMESPACE = "niri-edge-switch"
NIRI = shutil.which("niri") or "/usr/bin/niri"
# 事件风暴（拖窗口、切换工作区）时合并查询，避免连续 fork niri msg
DEBOUNCE_MS = 250
# 事件流断开后的重连间隔
RECONNECT_DELAY_S = 2.0

_PRELOAD_CANDIDATES = (
    "/usr/lib/libgtk4-layer-shell.so",
    "/usr/lib64/libgtk4-layer-shell.so",
)


def _ensure_preload():
    """Python 会先加载 libwayland，导致 gtk4-layer-shell 初始化 layer surface 失败。

    gtk4-layer-shell 官方给的免重编译解法就是预加载该库，这里自动补上，
    保证直接跑脚本和由 systemd（unit 里已设 LD_PRELOAD）拉起都能工作。
    """
    if "libgtk4-layer-shell" in os.environ.get("LD_PRELOAD", ""):
        return
    for path in _PRELOAD_CANDIDATES:
        if os.path.exists(path):
            os.environ["LD_PRELOAD"] = path
            os.execv(sys.executable, [sys.executable, os.path.abspath(__file__), *sys.argv[1:]])
    print("警告: 未找到 libgtk4-layer-shell.so，layer surface 可能无法创建", file=sys.stderr)


_ensure_preload()

import gi  # noqa: E402

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")
gi.require_version("Gtk4LayerShell", "1.0")

from gi.repository import Gdk, GLib, Gtk, Gtk4LayerShell as LayerShell  # noqa: E402

# 悬停提示加在 window 节点上：探针实测该节点从透明切到半透明可正常上色
CSS = b"""
window, window.background { background-color: transparent; }
.strip { background-color: transparent; }
window.hover { background-color: rgba(255, 255, 255, 0.14); }
window.hover-left { border-radius: 0 8px 8px 0; }
window.hover-right { border-radius: 8px 0 0 8px; }
"""


def _column_index(window):
    """窗口在滚动布局里的列号；浮动窗口或查询不到时为 None。"""
    pos = (window.get("layout") or {}).get("pos_in_scrolling_layout")
    return pos[0] if pos else None


def query_neighbors():
    """返回 (左侧是否还有列, 右侧是否还有列)；查询失败返回 None（保持原状态）。"""
    try:
        out = subprocess.run(
            [NIRI, "msg", "--json", "windows"],
            capture_output=True,
            text=True,
            timeout=3,
            check=True,
        )
        windows = json.loads(out.stdout)
    except Exception as exc:  # noqa: BLE001 - IPC 失败只降级，不杀掉守护进程
        print(f"查询窗口列表失败: {exc}", file=sys.stderr, flush=True)
        return None

    focused = next((w for w in windows if w.get("is_focused")), None)
    if focused is None or focused.get("is_floating"):
        return (False, False)

    focused_col = _column_index(focused)
    if focused_col is None:
        return (False, False)

    columns = [
        col
        for col in (
            _column_index(w)
            for w in windows
            if w.get("workspace_id") == focused.get("workspace_id") and not w.get("is_floating")
        )
        if col is not None
    ]
    if not columns:
        return (False, False)
    return (focused_col > min(columns), focused_col < max(columns))


class NiriWatcher:
    """订阅 niri 事件流，状态变化时回调 (has_left, has_right) 与总览开关。"""

    def __init__(self, on_neighbors, on_overview):
        self._on_neighbors = on_neighbors
        self._on_overview = on_overview
        self._last = None
        self._overview_open = False
        self._refresh_pending = False

    def start(self):
        threading.Thread(target=self._consume_events, name="niri-event-stream", daemon=True).start()
        self.refresh()

    def refresh(self):
        if self._overview_open:
            return
        state = query_neighbors()
        if state is None or state == self._last:
            return
        self._last = state
        self._on_neighbors(*state)

    def _consume_events(self):
        while True:
            try:
                proc = subprocess.Popen(
                    [NIRI, "msg", "--json", "event-stream"],
                    stdout=subprocess.PIPE,
                    text=True,
                )
                for line in proc.stdout:
                    self._handle_event(line)
            except Exception as exc:  # noqa: BLE001 - 事件流断了就重连
                print(f"事件流异常: {exc}", file=sys.stderr, flush=True)
            # 事件流退出（niri 重启等）后稍等重连
            time.sleep(RECONNECT_DELAY_S)

    def _handle_event(self, line):
        try:
            event = json.loads(line)
        except ValueError:
            return
        if not isinstance(event, dict) or not event:
            return
        name = next(iter(event))
        payload = event[name]

        # 总览里热区会浮在总览之上，点击语义混乱，直接隐藏
        if name == "OverviewOpenedOrClosed":
            is_open = bool((payload or {}).get("is_open"))
            if is_open != self._overview_open:
                self._overview_open = is_open
                GLib.idle_add(self._on_overview, is_open)
                if not is_open:
                    GLib.idle_add(self._schedule_refresh)
            return

        GLib.idle_add(self._schedule_refresh)

    def _schedule_refresh(self):
        """合并短时间内的连续事件。"""
        if self._refresh_pending or self._overview_open:
            return GLib.SOURCE_REMOVE
        self._refresh_pending = True
        GLib.timeout_add(DEBOUNCE_MS, self._do_refresh)
        return GLib.SOURCE_REMOVE

    def _do_refresh(self):
        self._refresh_pending = False
        self.refresh()
        return GLib.SOURCE_REMOVE


class Strip:
    """单侧热区：一个 overlay 层的 layer-shell 表面。"""

    def __init__(self, app, monitor, side):
        self.side = side
        self._shown = False

        self.window = Gtk.Window(application=app)
        LayerShell.init_for_window(self.window)
        LayerShell.set_layer(self.window, LayerShell.Layer.OVERLAY)
        LayerShell.set_namespace(self.window, NAMESPACE)
        LayerShell.set_monitor(self.window, monitor)
        # 独占区 0：只当输入热区，不参与可用区计算（热区占位由 layout.kdl 的 struts 负责）
        LayerShell.set_exclusive_zone(self.window, 0)
        LayerShell.set_anchor(self.window, LayerShell.Edge.TOP, True)
        LayerShell.set_anchor(self.window, LayerShell.Edge.BOTTOM, True)
        LayerShell.set_anchor(
            self.window,
            LayerShell.Edge.LEFT if side == "left" else LayerShell.Edge.RIGHT,
            True,
        )
        self.window.set_default_size(STRIP_WIDTH, 0)

        self.box = Gtk.Box()
        self.box.add_css_class("strip")
        self.box.add_css_class(f"strip-{side}")
        self.window.set_child(self.box)

        self.window.add_css_class(f"hover-{side}")
        motion = Gtk.EventControllerMotion()
        motion.connect("enter", lambda *_: self.window.add_css_class("hover"))
        motion.connect("leave", lambda *_: self.window.remove_css_class("hover"))
        self.window.add_controller(motion)

        click = Gtk.GestureClick()
        click.set_button(Gdk.BUTTON_PRIMARY)
        click.connect("pressed", self._on_pressed)
        self.window.add_controller(click)

    def _on_pressed(self, _gesture, n_press, _x, _y):
        if n_press > 1:
            return
        action = "focus-column-left" if self.side == "left" else "focus-column-right"
        subprocess.Popen(
            [NIRI, "msg", "action", action],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

    def set_shown(self, shown):
        if shown == self._shown:
            return
        self._shown = shown
        if shown:
            self.window.present()
        else:
            self.window.remove_css_class("hover")
            self.window.set_visible(False)

    def destroy(self):
        self.window.destroy()


class EdgeSwitch:
    """给每个显示器创建左右两条热区，并按聚焦窗口状态决定是否可点。"""

    def __init__(self, app):
        self._app = app
        self._strips = []
        self._neighbors = (True, True)  # 查询失败时保持可用
        self._overview_open = False
        self._watcher = NiriWatcher(self._apply_neighbors, self._apply_overview)
        Gdk.Display.get_default().get_monitors().connect("items-changed", lambda *_: self._rebuild())

    def start(self):
        self._rebuild()
        self._watcher.start()

    def _rebuild(self):
        for strip in self._strips:
            strip.destroy()
        self._strips = []
        display = Gdk.Display.get_default()
        monitors = display.get_monitors()
        for index in range(monitors.get_n_items()):
            monitor = monitors.get_item(index)
            for side in ("left", "right"):
                self._strips.append(Strip(self._app, monitor, side))
        self._apply_state()

    def _apply_neighbors(self, has_left, has_right):
        self._neighbors = (has_left, has_right)
        self._apply_state()

    def _apply_overview(self, is_open):
        self._overview_open = is_open
        self._apply_state()

    def _apply_state(self):
        for strip in self._strips:
            if self._overview_open:
                strip.set_shown(False)
            else:
                strip.set_shown(self._neighbors[0] if strip.side == "left" else self._neighbors[1])


def main():
    app = Gtk.Application(application_id="dev.niri.edge-switch")
    app.hold()  # 热区全部隐藏时也不要退出

    def on_activate(application):
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(
            Gdk.Display.get_default(),
            provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )
        EdgeSwitch(application).start()

    app.connect("activate", on_activate)
    return app.run(None)


if __name__ == "__main__":
    raise SystemExit(main())