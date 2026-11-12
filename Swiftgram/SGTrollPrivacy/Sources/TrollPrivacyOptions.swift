import Foundation

/// Privacy toggles shown in the TrollGram settings screen.
///
/// Storage is the local `app.trollgram.ios.privacy` suite and every protection
/// ships enabled. `TrollPrivacyBootstrap` mirrors the values into TelegramCore.
public enum TrollPrivacyOptions {
    public static var defaults: UserDefaults {
        return UserDefaults(suiteName: "app.trollgram.ios.privacy") ?? .standard
    }

    public static func flag(_ key: String) -> Bool {
        if defaults.object(forKey: key) == nil {
            return true
        }
        return defaults.bool(forKey: key)
    }

    /// Key of the row the user just flipped; consumed by the settings controller.
    public static var pendingKey: String?

    public static func setFlag(_ key: String, _ value: Bool) {
        defaults.set(value, forKey: key)
        defaults.synchronize()
    }

    public static var rows: [(key: String, title: String)] {
        return [
            ("tg_privacy_anti_delete", "Anti-Delete Messages"),
            ("tg_privacy_edit_history", "Edit History"),
            ("tg_privacy_ghost_mode", "Ghost Mode"),
            ("tg_privacy_ghost_hide_online", "Hide Online Status"),
            ("tg_privacy_ghost_hide_read", "Hide Read Receipts"),
            ("tg_privacy_ghost_hide_typing", "Hide Typing Status"),
            ("tg_privacy_ghost_hide_upload", "Hide Uploading Status"),
            ("tg_privacy_view_once", "View Once Media"),
            ("tg_privacy_allow_copy", "Copy Protected Content"),
            ("tg_privacy_remove_sponsored", "Remove Sponsored Messages")
        ]
    }
}
