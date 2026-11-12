"""exteraGram SDK compatibility layer: `ui.settings` widgets.

Widgets are plain value objects. `PythonPluginManager` renders them natively
in the TrollGram settings screen; plugins only describe what they need.
"""


class _Item:
    def __init__(self, **kwargs):
        for key, value in kwargs.items():
            setattr(self, key, value)


class Header(_Item):
    def __init__(self, text="", **kwargs):
        super().__init__(text=text, **kwargs)


class Divider(_Item):
    def __init__(self, text="", **kwargs):
        super().__init__(text=text, **kwargs)


class Text(_Item):
    def __init__(self, text="", **kwargs):
        super().__init__(text=text, **kwargs)


class Switch(_Item):
    def __init__(self, key="", text="", default=False, **kwargs):
        super().__init__(key=key, text=text, value=default, default=default, **kwargs)


class Selector(_Item):
    def __init__(self, key="", text="", items=None, default=0, **kwargs):
        super().__init__(key=key, text=text, items=items or [], value=default, default=default, **kwargs)


class Input(_Item):
    def __init__(self, key="", text="", default="", **kwargs):
        super().__init__(key=key, text=text, value=default, default=default, **kwargs)


__all__ = ["Header", "Divider", "Switch", "Selector", "Input", "Text"]
