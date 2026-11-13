import Foundation

/// Dispatch entry point used by `ChatController.sendMessages`.
///
/// Kept tiny so the hook in the core TelegramUI module stays readable; the
/// real work lives in `PythonPluginManager`.
public enum PythonPluginsRuntime {
    public static var isPluginHostAvailable: Bool {
        return PythonPluginManager.shared.isInterpreterAvailable
    }

    /// Returns `true` when a plugin cancelled sending.
    @discardableResult
    public static func dispatchSendMessageHook(peerId: Any, messages: inout [Any]) -> Bool {
        guard PythonPluginManager.shared.hasEnabledPlugins else {
            return false
        }
        return PythonPluginManager.shared.dispatchSendMessageHook(peerId: peerId, messages: &messages)
    }
}
