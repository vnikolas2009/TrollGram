"""exteraGram plugin SDK compatibility layer (base_plugin).

This module is imported by plugins written for exteraGram. It mirrors the
public surface of `base_plugin` closely enough for ordinary plugins to load
and run inside TrollGram.
"""

import enum

try:
    import trollgram_bridge
except Exception:  # pragma: no cover - stub mode
    trollgram_bridge = None


class HookStrategy(enum.IntEnum):
    DEFAULT = 0
    BEFORE = 1
    AFTER = 2
    REPLACE = 3
    SKIP = 4


class HookResult(enum.IntEnum):
    DEFAULT = 0
    MODIFIED = 1
    CANCELLED = 2


def _settings_path(plugin_id):
    if trollgram_bridge is None:
        return None
    try:
        return trollgram_bridge.plugin_data_dir() + "/" + plugin_id + ".json"
    except Exception:
        return None


class BasePlugin:
    """Base class every exteraGram-style plugin inherits from."""

    #: display name shown in the TrollGram plugin manager
    name = "Unnamed Plugin"
    description = ""
    #: list of `ui.settings` widgets, persisted to Documents/PluginsData/
    settings = []

    def __init__(self):
        self.id = self.__class__.__module__.split(".")[-1]
        self._enabled = True
        self._load_settings()

    # -- settings persistence ----------------------------------------------
    def _load_settings(self):
        path = _settings_path(self.id)
        if not path:
            return
        try:
            import json
            with open(path, "r", encoding="utf-8") as handle:
                stored = json.load(handle)
        except Exception:
            return
        for index, item in enumerate(self.settings):
            key = getattr(item, "key", None) or str(index)
            if key in stored:
                item.value = stored[key]

    def save_settings(self):
        path = _settings_path(self.id)
        if not path:
            return
        payload = {}
        for index, item in enumerate(self.settings):
            key = getattr(item, "key", None) or str(index)
            payload[key] = getattr(item, "value", None)
        try:
            import json
            with open(path, "w", encoding="utf-8") as handle:
                json.dump(payload, handle, indent=2)
        except Exception:
            pass

    def get_setting(self, key, default=None):
        for item in self.settings:
            if getattr(item, "key", None) == key:
                return getattr(item, "value", default)
        return default

    def set_setting(self, key, value):
        for item in self.settings:
            if getattr(item, "key", None) == key:
                item.value = value
                break
        self.save_settings()

    # -- hooks (overridden by plugins) --------------------------------------
    def on_plugin_load(self):
        pass

    def on_plugin_unload(self):
        pass

    def on_send_message_hook(self, account, message, text=None):
        return HookResult.DEFAULT

    def on_update_hook(self, *args, **kwargs):
        return HookResult.DEFAULT

    def on_settings_hook(self, *args, **kwargs):
        return None


HookMode = HookStrategy
