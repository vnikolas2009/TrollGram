"""TrollGram native bridge, implemented in pure Python.

exteraGram plugins import this module (usually through `client_utils` or
`android_utils`) to reach the client. Because TrollGram embeds CPython but
does not build a C extension module, the bridge records every call locally:

* `log()` / `show_toast()` / `show_undo()` go to the plugin log
  (`Documents/PluginsData/log.txt`) which the in-app plugin manager shows.
* `send_message()` / `edit_message()` are appended to
  `Documents/PluginsData/outbox.jsonl` so future builds can replay them.

Everything is best-effort and never raises, so a plugin cannot crash the host.
"""

from __future__ import annotations

import json
import os
import sys
import time

_DATA_DIR_ENV = "TROLLGRAM_DATA_DIR"
_FALLBACK = os.path.join(os.path.expanduser("~"), "Documents", "PluginsData")


def _data_dir():
    path = os.environ.get(_DATA_DIR_ENV) or _FALLBACK
    try:
        os.makedirs(path, exist_ok=True)
    except Exception:
        pass
    return path


def plugin_data_dir():
    """Absolute path of the directory plugins may use for their own files."""
    return _data_dir()


def log(text):
    try:
        with open(os.path.join(_data_dir(), "log.txt"), "a", encoding="utf-8") as handle:
            handle.write("[py] %s\n" % (text,))
    except Exception:
        pass
    return True


def show_toast(text):
    log("toast: %s" % (text,))
    return True


def show_undo(title, text):
    log("undo: %s (%s)" % (text, title))
    return True


def _append(record):
    try:
        with open(os.path.join(_data_dir(), "outbox.jsonl"), "a", encoding="utf-8") as handle:
            handle.write(json.dumps(record, ensure_ascii=False) + "\n")
    except Exception:
        pass


def send_message(account, peer, text):
    _append({"op": "send_message", "account": account, "peer": peer, "text": text, "at": time.time()})
    return True


def edit_message(account, peer, message_id, text):
    _append({"op": "edit_message", "account": account, "peer": peer, "message_id": message_id, "text": text, "at": time.time()})
    return True


def run_on_ui_thread(name):
    log("ui: %s" % (name,))
    return True


def get_current_account():
    value = os.environ.get("TROLLGRAM_ACCOUNT")
    return value if value is not None else "0"


def ready():
    return True


__all__ = [
    "edit_message",
    "get_current_account",
    "log",
    "plugin_data_dir",
    "ready",
    "run_on_ui_thread",
    "send_message",
    "show_toast",
    "show_undo",
]
