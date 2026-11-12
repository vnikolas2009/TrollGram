#if canImport(Python)
import Foundation
import Python

/// Registers the `trollgram_bridge` module that plugins import from
/// `client_utils` / `android_utils`.
///
/// The C function pointers live at file scope so CPython keeps a valid
/// reference for the lifetime of the process.
enum PythonBridge {
    static var handlers = BridgeHandlers.empty

    static func register(_ handlers: BridgeHandlers) {
        PythonBridge.handlers = handlers

        var methods: [PyMethodDef] = []
        for (name, fn) in bridgeMethods {
            methods.append(PyMethodDef(
                ml_name: name,
                ml_meth: fn,
                ml_flags: METH_VARARGS,
                ml_doc: name
            ))
        }
        methods.append(PyMethodDef(ml_name: nil, ml_meth: nil, ml_flags: 0, ml_doc: nil))

        methods.withUnsafeMutableBufferPointer { buffer in
            bridgeModuleDefinition.m_methods = buffer.baseAddress
            bridgeModuleDefinition.m_methods = buffer.baseAddress
            if let module = PyModule_Create2(&bridgeModuleDefinition, 1013) {
                PyImport_AppendInittab("trollgram_bridge", bridgeModuleInit)
                PyImport_AddModule("trollgram_bridge")
                _ = PyModule_AddObject(module, "ready", PyBool_FromLong(1))
            }
        }
    }
}

// MARK: - C bridge helpers

func bridgeArgString(_ args: UnsafeMutablePointer<PyObject>?, _ index: Int) -> String {
    guard let args, index < PyTuple_Size(args) else {
        return ""
    }
    guard let item = PyTuple_GetItem(args, index), let cString = PyUnicode_AsUTF8(item) else {
        return ""
    }
    return String(cString: cString)
}

func bridgeOk() -> UnsafeMutablePointer<PyObject>? {
    return PyBool_FromLong(1)
}

private var bridgeModuleDefinition = PyModuleDef(
    m_base: PyModuleDef_HEAD_INIT,
    m_name: "trollgram_bridge",
    m_doc: "TrollGram native bridge",
    m_size: -1,
    m_methods: nil,
    m_slots: nil,
    m_traverse: nil,
    m_clear: nil,
    m_free: nil
)

@_cdecl("PyInit_trollgram_bridge")
func bridgeModuleInit() -> UnsafeMutablePointer<PyObject>? {
    return PyModule_Create2(&bridgeModuleDefinition, 1013)
}

@_cdecl("tg_bridge_send_message")
func tg_bridge_send_message(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    PythonBridge.handlers.sendMessage(bridgeArgString(args, 0), bridgeArgString(args, 1), bridgeArgString(args, 2))
    return bridgeOk()
}

@_cdecl("tg_bridge_edit_message")
func tg_bridge_edit_message(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    let messageId = Int32(bridgeArgString(args, 2)) ?? 0
    PythonBridge.handlers.editMessage(bridgeArgString(args, 1), messageId, bridgeArgString(args, 3))
    return bridgeOk()
}

@_cdecl("tg_bridge_show_toast")
func tg_bridge_show_toast(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    PythonBridge.handlers.showToast(bridgeArgString(args, 0))
    return bridgeOk()
}

@_cdecl("tg_bridge_show_undo")
func tg_bridge_show_undo(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    PythonBridge.handlers.showUndo(bridgeArgString(args, 0), bridgeArgString(args, 1))
    return bridgeOk()
}

@_cdecl("tg_bridge_log")
func tg_bridge_log(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    PythonBridge.handlers.log(bridgeArgString(args, 0))
    return bridgeOk()
}

@_cdecl("tg_bridge_plugin_data_dir")
func tg_bridge_plugin_data_dir(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    return PyUnicode_FromString(PythonBridge.handlers.pluginDataDirectory())
}

@_cdecl("tg_bridge_run_on_ui_thread")
func tg_bridge_run_on_ui_thread(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    PythonBridge.handlers.runOnUIThread(bridgeArgString(args, 0))
    return bridgeOk()
}

@_cdecl("tg_bridge_get_current_account")
func tg_bridge_get_current_account(_ self: UnsafeMutablePointer<PyObject>?, _ args: UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>? {
    return PyUnicode_FromString(PythonBridge.handlers.currentAccount())
}

private let bridgeMethods: [(String, @convention(c) (UnsafeMutablePointer<PyObject>?, UnsafeMutablePointer<PyObject>?) -> UnsafeMutablePointer<PyObject>?)] = [
    ("send_message", tg_bridge_send_message),
    ("edit_message", tg_bridge_edit_message),
    ("show_toast", tg_bridge_show_toast),
    ("show_undo", tg_bridge_show_undo),
    ("log", tg_bridge_log),
    ("plugin_data_dir", tg_bridge_plugin_data_dir),
    ("run_on_ui_thread", tg_bridge_run_on_ui_thread),
    ("get_current_account", tg_bridge_get_current_account)
]

/// Native callbacks the Python side can invoke.
struct BridgeHandlers {
    var sendMessage: (_ account: String, _ peer: String, _ text: String) -> Void
    var editMessage: (_ peer: String, _ messageId: Int32, _ text: String) -> Void
    var showToast: (_ text: String) -> Void
    var showUndo: (_ title: String, _ text: String) -> Void
    var log: (_ text: String) -> Void
    var pluginDataDirectory: () -> String
    var runOnUIThread: (_ name: String) -> Void
    var currentAccount: () -> String

    static let empty = BridgeHandlers(
        sendMessage: { _, _, _ in },
        editMessage: { _, _, _ in },
        showToast: { _ in },
        showUndo: { _, _ in },
        log: { _ in },
        pluginDataDirectory: { "" },
        runOnUIThread: { _ in },
        currentAccount: { "0" }
    )
}
#endif
