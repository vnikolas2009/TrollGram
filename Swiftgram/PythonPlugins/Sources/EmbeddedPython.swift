#if canImport(Python)
import Foundation
import Python
#endif
import Foundation

/// Thin Swift wrapper around the embedded CPython 3.11 interpreter.
///
/// Compiled only when the `Python` module (`Python.xcframework`) is linked;
/// otherwise every call is a no-op and plugins stay in stub mode.
final class EmbeddedPython {
    static let shared = EmbeddedPython()

    private var isStarted = false

    private init() {}

    var isAvailable: Bool {
        #if canImport(Python)
        return true
        #else
        return false
        #endif
    }

    /// Starts CPython with `PYTHONHOME` pointing at the bundled stdlib.
    func start(pluginDirectory: String, dataDirectory: String, bridgeRegistered: Bool) -> Bool {
        #if canImport(Python)
        if self.isStarted {
            return true
        }
        guard let resources = Bundle.main.resourcePath else {
            return false
        }
        // Bundle layout: Resources/python/lib/python3.11 (see build-system/setup_python.py).
        let home = resources + "/python"
        setenv("PYTHONHOME", home, 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)
        if bridgeRegistered {
            PyImport_AppendInittab("trollgram_bridge", bridgeModuleInit)
        }

        Py_Initialize()

        let paths = [
            pluginDirectory,
            home + "/lib/python3.11",
            home + "/lib/python3.11/lib-dynload",
            resources + "/python_stdlib",
            dataDirectory
        ]
        for path in paths {
            self.run("import sys, os\np = os.path.realpath(r'''\(path)''')\nif p not in sys.path:\n    sys.path.insert(0, p)")
        }
        self.isStarted = true
        return true
        #else
        return false
        #endif
    }

    /// Executes a Python snippet. Returns the traceback on failure.
    @discardableResult
    func run(_ code: String) -> String? {
        #if canImport(Python)
        if PyRun_SimpleString(code) == 0 {
            return nil
        }
        var message = "unknown Python error"
        if let type = PyErr_Occurred(), let text = PyObject_Str(type), let cString = PyUnicode_AsUTF8(text) {
            message = String(cString: cString)
        }
        PyErr_Clear()
        return message
        #else
        return "Python runtime is not linked"
        #endif
    }

    /// Runs the plugin's `on_send_message_hook`; returns the hook code
    /// (0 = default, 1 = modified, 2 = cancelled).
    func dispatchSendMessageHook(module: String, text: String) -> Int {
        #if canImport(Python)
        let escapedModule = module.replacingOccurrences(of: "'", with: "\\'")
        let escapedText = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "'", with: "\\'")
        let code = """
        import importlib
        import sys
        import builtins
        _tg_name = '\(escapedModule)'
        if _tg_name in sys.modules:
            importlib.reload(sys.modules[_tg_name])
        _tg_module = importlib.import_module(_tg_name)
        _tg_hook = getattr(_tg_module, 'on_send_message_hook', None)
        _tg_code = 0
        if _tg_hook is not None:
            _tg_code = int(_tg_hook(None, None, '\(escapedText)') or 0)
        with open(r'''\(self.hookResultPath)''', 'w') as _f:
            _f.write(str(_tg_code))
        """
        if self.run(code) != nil {
            return 0
        }
        guard let raw = try? String(contentsOfFile: self.hookResultPath, encoding: .utf8),
              let value = Int(raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return 0
        }
        return value
        #else
        return 0
        #endif
    }

    /// Scratch file the plugin hook writes its result code to.
    private lazy var hookResultPath: String = {
        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        return documents + "/PluginsData/.hook_result"
    }()

    func finalize() {
        #if canImport(Python)
        if self.isStarted {
            Py_FinalizeEx()
            self.isStarted = false
        }
        #endif
    }
}
