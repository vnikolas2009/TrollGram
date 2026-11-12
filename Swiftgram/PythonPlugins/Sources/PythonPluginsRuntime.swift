import Foundation

/// Dispatch entry point used by `ChatController.sendMessages`.
///
/// Kept dependency-free so the hook can be called from the core TelegramUI
/// module without pulling the whole plugin host.
public enum PythonPluginsRuntime {
    public static var isPluginHostAvailable: Bool {
        #if TROLLGRAM_PLUGINS
        return true
        #else
        return false
        #endif
    }

    /// Returns `true` when a plugin cancelled sending.
    @discardableResult
    public static func dispatchSendMessageHook(peerId: Any, messages: inout [Any]) -> Bool {
        guard self.isPluginHostAvailable, PythonPluginManager.shared.hasEnabledPlugins else {
            return false
        }
        return PythonPluginManager.shared.dispatchSendMessageHook(peerId: peerId, messages: &messages)
    }
}
