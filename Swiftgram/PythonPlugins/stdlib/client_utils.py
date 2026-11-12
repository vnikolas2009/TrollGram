"""Bridge between Python plugins and TrollGram (TelegramCore / UI thread).

Every call is marshalled to the native side through the `trollgram_bridge`
module registered by `PythonPluginManager`. If the bridge is unavailable
(unit tests, stub mode) calls become no-ops instead of raising.
"""

try:
    import trollgram_bridge as _native
except Exception:  # pragma: no cover - stub mode
    _native = None


def _call(name, *args, **kwargs):
    if _native is None:
        return None
    fn = getattr(_native, name, None)
    if fn is None:
        return None
    return fn(*args, **kwargs)


def get_accounts():
    return _call("get_accounts") or []


def get_current_account():
    return _call("get_current_account")


def send_message(account, peer, text, reply_to=None):
    """Send a text message. `peer` may be an id, @username or chat title."""
    return _call("send_message", account, peer, text, reply_to)


def edit_message(account, peer, message_id, text):
    return _call("edit_message", account, peer, message_id, text)


def delete_messages(account, peer, message_ids):
    return _call("delete_messages", account, peer, list(message_ids))


def get_messages(account, peer, limit=20):
    return _call("get_messages", account, peer, limit) or []


def run_on_ui_thread(fn, *args, **kwargs):
    """Queue `fn` on the main thread. Arguments must be primitives."""
    return _call("run_on_ui_thread", fn.__name__ if hasattr(fn, "__name__") else str(fn), *args, **kwargs)


def show_toast(text):
    return _call("show_toast", text)


def show_undo(title, text):
    return _call("show_undo", title, text)


def log(text):
    return _call("log", text)


def plugin_data_dir():
    return _call("plugin_data_dir")
