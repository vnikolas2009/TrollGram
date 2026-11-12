"""exteraGram plugin SDK compatibility layer (base_plugin).

This module is imported by plugins written for exteraGram. It mirrors the
public surface of `base_plugin` closely enough for ordinary plugins to load
and run inside TrollGram.
"""

from enum import IntEnum


class HookStrategy(IntEnum):
    DEFAULT = 0
    BEFORE = 1
    AFTER = 2
    REPLACE = 3
    SKIP = 4


class HookResult(IntEnum):
    DEFAULT = 0
    MODIFIED = 1
    CANCELLED = 2


class BasePlugin:
    """Base class every exteraGram-style plugin inherits from."""

    #: display name shown in the TrollGram plugin manager
    name = "Unnamed Plugin"
    description = ""
    #: plugin configuration, persisted under Documents/PluginsData/<id>.json
    settings = []

    def __init__(self):
        self.id = self.__class__.__module__.split(".")[-1]
        self._enabled = True

    # -- settings -----------------------------------------------------------
    def get_setting(self, item):
        """Return the current value of the setting object passed to `__init__`."""
        return getattr(item, "value", None)

    def set_setting(self, item, value):
        item.value = value
        try:
            import trollgram_bridge
            trollgram_bridge.save_plugin_settings(self.id, self._serialized_settings())
        except Exception:
            pass

    def _serialized_settings(self):
        return {
            i.__class__.__name__ + "_" + str(idx): getattr(i, "value", None)
            for idx, i in enumerate(self.settings)
        }

    # -- hooks (overridden by plugins) --------------------------------------
    def on_plugin_load(self):
        pass

    def on_plugin_unload(self):
        pass

    def on_send_message_hook(self, account, message, *args, **kwargs):
        return HookResult.DEFAULT

    def on_update_hook(self, *args, **kwargs):
        return HookResult.DEFAULT

    def on_settings_hook(self, *args, **kwargs):
        return None


# Convenience aliases used by some plugins
base_plugin = __name__
HookMode = HookStrategy
