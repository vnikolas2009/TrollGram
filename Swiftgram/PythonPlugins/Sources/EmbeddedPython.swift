#if canImport(Python)
import Python
#endif
import Foundation
import ZipArchive

/// Thin Swift wrapper around the embedded CPython 3.11 interpreter.
///
/// Compiled only when the `Python` module (`Python.xcframework`) is linked;
/// otherwise every call is a no-op and plugins stay in stub mode.
///
/// Only the stable "run this snippet" surface of the CPython API is used here.
/// The `trollgram_bridge` extension module that plugins import is implemented
/// in Python (`stdlib/trollgram_bridge.py`), which keeps the Swift side free
/// of `PyModuleDef`/`PyMethodDef` plumbing.
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

    /// Starts CPython with `PYTHONHOME` pointing at the extracted stdlib.
    func start(pluginDirectory: String, dataDirectory: String) -> Bool {
        #if canImport(Python)
        if self.isStarted {
            return true
        }
        guard let resources = Bundle.main.resourcePath else {
            return false
        }
        guard let home = self.prepareStdlib(resources: resources) else {
            NSLog("[TrollGram] Python stdlib is unavailable")
            return false
        }
        let stdlib = home + "/lib/python3.11"
        setenv("PYTHONHOME", home, 1)
        setenv("PYTHONPATH", stdlib + ":" + pluginDirectory + ":" + dataDirectory, 1)
        setenv("TROLLGRAM_DATA_DIR", dataDirectory, 1)
        setenv("PYTHONDONTWRITEBYTECODE", "1", 1)

        Py_Initialize()

        let paths = [
            pluginDirectory,
            stdlib,
            stdlib + "/lib-dynload",
            dataDirectory
        ]
        for path in paths {
            self.run("import sys, os\np = os.path.realpath(r'''\(path)''')\nif p not in sys.path:\n    sys.path.insert(0, p)")
        }
        if let error = self.run("import encodings, os, sys") {
            NSLog("[TrollGram] Python bootstrap failed: \(error)")
            return false
        }
        self.isStarted = true
        return true
        #else
        return false
        #endif
    }

    /// Extracts `python.zip` from the app bundle once and returns the root that
    /// `PYTHONHOME` expects (`lib/python3.11` lives directly inside it).
    private func prepareStdlib(resources: String) -> String? {
        let fileManager = FileManager.default
        let support = (NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()) + "/TrollGram"
        let home = support + "/python"
        if fileManager.fileExists(atPath: home + "/lib/python3.11/os.py") {
            return home
        }
        guard let archive = Bundle.main.path(forResource: "python", ofType: "zip") else {
            NSLog("[TrollGram] python.zip is not bundled (looked in \(resources))")
            return nil
        }
        do {
            try fileManager.createDirectory(atPath: support, withIntermediateDirectories: true)
            try? fileManager.removeItem(atPath: home)
            guard SSZipArchive.unzipFileAtPath(archive, toDestination: home) else {
                NSLog("[TrollGram] Failed to extract python.zip")
                return nil
            }
        } catch {
            NSLog("[TrollGram] Failed to prepare python stdlib: \(error)")
            return nil
        }
        return fileManager.fileExists(atPath: home + "/lib/python3.11/os.py") ? home : nil
    }

    /// Executes a Python snippet. Returns the error description on failure.
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
