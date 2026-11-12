"""exteraGram SDK compatibility layer: `hook_utils` stub.

Full method hooking is not supported on iOS. The module exists so plugins
that `import hook_utils` at load time never crash; hooks become no-ops.
"""

_MISSING = object()


def _noop(*args, **kwargs):
    return None


def skip_hook(*args, **kwargs):
    """Mark the following code path as "do not run the original method"."""
    return False


def get_method_original(method):
    return method


def find_class(*args, **kwargs):
    return None


def find_method(*args, **kwargs):
    return _noop


def hook_method(*args, **kwargs):
    return _noop


def unhook_method(*args, **kwargs):
    return None


def hook_all_methods(*args, **kwargs):
    return _noop


class Hook:
    def __init__(self, *args, **kwargs):
        pass

    def __enter__(self):
        return self

    def __exit__(self, *exc):
        return False
