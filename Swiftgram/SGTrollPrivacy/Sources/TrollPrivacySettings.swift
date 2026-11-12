import Foundation
import SGSimpleSettings

// TrollGram privacy / anti-censorship toggles.
// All flags are local-only: they never reach Telegram servers.
public enum TrollPrivacySettings {
    private static let suiteName = "app.trollgram.ios.privacy"

    private static var defaults: UserDefaults {
        return UserDefaults(suiteName: suiteName) ?? .standard
    }

    private enum Key: String {
        case antiDelete = "tg_privacy_anti_delete"
        case editHistory = "tg_privacy_edit_history"
        case ghostMode = "tg_privacy_ghost_mode"
        case ghostHideOnline = "tg_privacy_ghost_hide_online"
        case ghostHideReadReceipts = "tg_privacy_ghost_hide_read"
        case ghostHideTyping = "tg_privacy_ghost_hide_typing"
        case ghostHideUpload = "tg_privacy_ghost_hide_upload"
        case viewOnceUnlock = "tg_privacy_view_once"
        case allowCopyProtected = "tg_privacy_allow_copy"
        case removeSponsored = "tg_privacy_remove_sponsored"
    }

    private static func get(_ key: Key, default defaultValue: Bool) -> Bool {
        if defaults.object(forKey: key.rawValue) == nil {
            return defaultValue
        }
        return defaults.bool(forKey: key.rawValue)
    }

    private static func set(_ key: Key, _ value: Bool) {
        defaults.set(value, forKey: key.rawValue)
        defaults.synchronize()
    }

    /// Keep deleted messages in chat history (local cache only).
    public static var antiDelete: Bool {
        get { get(.antiDelete, default: false) }
        set { set(.antiDelete, newValue) }
    }

    /// Store previous versions of edited messages.
    public static var editHistory: Bool {
        get { get(.editHistory, default: false) }
        set { set(.editHistory, newValue) }
    }

    /// Master switch for Ghost Mode.
    public static var ghostMode: Bool {
        get { get(.ghostMode, default: false) }
        set { set(.ghostMode, newValue) }
    }

    public static var ghostHideOnline: Bool {
        get { return ghostMode && get(.ghostHideOnline, default: true) }
        set { set(.ghostHideOnline, newValue) }
    }

    public static var ghostHideReadReceipts: Bool {
        get { return ghostMode && get(.ghostHideReadReceipts, default: true) }
        set { set(.ghostHideReadReceipts, newValue) }
    }

    public static var ghostHideTyping: Bool {
        get { return ghostMode && get(.ghostHideTyping, default: true) }
        set { set(.ghostHideTyping, newValue) }
    }

    public static var ghostHideUpload: Bool {
        get { return ghostMode && get(.ghostHideUpload, default: true) }
        set { set(.ghostHideUpload, newValue) }
    }

    /// View self-destructing media without a trace.
    public static var viewOnceUnlock: Bool {
        get { get(.viewOnceUnlock, default: false) }
        set { set(.viewOnceUnlock, newValue) }
    }

    /// Allow copying / forwarding from noforwards channels.
    public static var allowCopyProtected: Bool {
        get { get(.allowCopyProtected, default: false) }
        set { set(.allowCopyProtected, newValue) }
    }

    /// Strip sponsored messages from channels.
    public static var removeSponsored: Bool {
        get { get(.removeSponsored, default: false) }
        set { set(.removeSponsored, newValue) }
    }

    public static var allToggles: [(title: String, isOn: Bool, set: (Bool) -> Void)] {
        return [
            ("Anti-Delete Messages", antiDelete, { antiDelete = $0 }),
            ("Edit History", editHistory, { editHistory = $0 }),
            ("Ghost Mode", ghostMode, { ghostMode = $0 }),
            ("Hide Online Status", ghostHideOnline, { ghostHideOnline = $0 }),
            ("Hide Read Receipts", ghostHideReadReceipts, { ghostHideReadReceipts = $0 }),
            ("Hide Typing Status", ghostHideTyping, { ghostHideTyping = $0 }),
            ("Hide Uploading Status", ghostHideUpload, { ghostHideUpload = $0 }),
            ("View Once Media", viewOnceUnlock, { viewOnceUnlock = $0 }),
            ("Copy Protected Content", allowCopyProtected, { allowCopyProtected = $0 }),
            ("Remove Sponsored Messages", removeSponsored, { removeSponsored = $0 })
        ]
    }
}
