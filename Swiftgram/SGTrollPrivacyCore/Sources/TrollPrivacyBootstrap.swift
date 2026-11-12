import Foundation
import TelegramCore

/// Mirrors TrollGram privacy flags into TelegramCore.
///
/// The flags live in the local `app.trollgram.ios.privacy` suite and are read
/// here directly, so the UI module only needs `SGTrollPrivacy` for the rows.
public enum TrollPrivacyBootstrap {
    private static var activated = false

    public static var defaults: UserDefaults {
        return UserDefaults(suiteName: "app.trollgram.ios.privacy") ?? .standard
    }

    public static func flag(_ key: String) -> Bool {
        if defaults.object(forKey: key) == nil {
            return true
        }
        return defaults.bool(forKey: key)
    }

    /// Call once at launch, before the network is started.
    public static func activate() {
        guard !activated else {
            return
        }
        activated = true
        mirror()
    }

    /// Re-reads every flag and pushes it into TelegramCore.
    public static func mirror() {
        TrollPrivacyRuntime.apply(
            ghostMode: flag("tg_privacy_ghost_mode"),
            hideOnline: flag("tg_privacy_ghost_hide_online"),
            hideReadReceipts: flag("tg_privacy_ghost_hide_read"),
            hideTyping: flag("tg_privacy_ghost_hide_typing"),
            hideUploading: flag("tg_privacy_ghost_hide_upload"),
            allowCopyProtectedPeers: flag("tg_privacy_allow_copy"),
            removeSponsoredMessages: flag("tg_privacy_remove_sponsored"),
            viewOnceMediaUnlocked: flag("tg_privacy_view_once")
        )
        TrollPrivacyRuntime.setArchiveFlags(
            antiDelete: flag("tg_privacy_anti_delete"),
            editHistory: flag("tg_privacy_edit_history")
        )
    }
}
