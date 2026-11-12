"""exteraGram SDK compatibility layer: `android_utils` shim.

exteraGram targets Android, so many plugins import `android_utils`. On iOS we
map the handful of commonly used callbacks onto their TrollGram equivalents.
"""

import client_utils


class _Handler:
    def post(self, fn):
        return client_utils.run_on_ui_thread(fn)


handler = _Handler()


def run_on_ui_thread(fn, *args, **kwargs):
    return client_utils.run_on_ui_thread(fn, *args, **kwargs)


def run_on_queue(fn, *args, **kwargs):
    # iOS has no Looper; execute on the main queue for determinism.
    return client_utils.run_on_ui_thread(fn, *args, **kwargs)


def show_toast(text):
    return client_utils.show_toast(text)


def get_application_context():
    return None
