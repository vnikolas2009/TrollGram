import Foundation
import SwiftSignalKit

/// Lightweight exteraGram plugin host.
///
/// Executes `.py` plugins against an embedded CPython 3.11 interpreter (see
/// `//third-party/python`). When the interpreter is not linked the manager
/// still lists, enables and persists plugin settings, but hooks are
/// pass-through.
public final class PythonPluginManager {
    public static let shared = PythonPluginManager()

    public struct Plugin: Equatable, Identifiable {
        public let id: String
        public let path: String
        public var title: String
        public var description: String
        public var isEnabled: Bool
        public var loadError: String?
    }

    public struct State {
        public var plugins: [Plugin] = []
        public var isLoading = false
        public var logs: [String] = []
    }

    private let queue = DispatchQueue(label: "app.trollgram.ios.plugins")
    private let statePromise = ValuePromise<State>(State(), ignoreRepeated: true)
    private let stateValue: Atomic<State>
    private var bridgeRegistered = false

    private let pluginsDirectory: String
    private let dataDirectory: String

    private init() {
        self.stateValue = Atomic(value: State())

        let documents = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first ?? NSTemporaryDirectory()
        self.pluginsDirectory = documents + "/Plugins"
        self.dataDirectory = documents + "/PluginsData"

        try? FileManager.default.createDirectory(atPath: self.pluginsDirectory, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: self.dataDirectory, withIntermediateDirectories: true)
    }

    public var state: Signal<State, NoError> {
        return self.statePromise.get()
    }

    public var pluginsDirectoryPath: String {
        return self.pluginsDirectory
    }

    /// `false` when `Python.xcframework` is not linked (stub mode).
    public var isInterpreterAvailable: Bool {
        return EmbeddedPython.shared.isAvailable
    }

    // MARK: - Interpreter

    private func ensureInterpreter() -> Bool {
        guard EmbeddedPython.shared.isAvailable else {
            return false
        }
        if !self.bridgeRegistered {
            #if canImport(Python)
            PythonBridge.register(BridgeHandlers(
                sendMessage: { [weak self] _, _, _ in
                    _ = self
                },
                editMessage: { _, _, _ in },
                showToast: { text in
                    self.appendLog("[toast] \(text)")
                },
                showUndo: { title, text in
                    self.appendLog("[undo] \(title): \(text)")
                },
                log: { text in
                    self.appendLog(text)
                },
                pluginDataDirectory: { [weak self] in
                    self?.dataDirectory ?? ""
                },
                runOnUIThread: { name in
                    self.appendLog("[ui] \(name)")
                },
                currentAccount: { "0" }
            ))
            #endif
            self.bridgeRegistered = true
        }
        return EmbeddedPython.shared.start(pluginDirectory: self.pluginsDirectory, dataDirectory: self.dataDirectory, bridgeRegistered: self.bridgeRegistered)
    }

    // MARK: - Discovery

    public func reload() {
        self.queue.async {
            let current = self.stateValue.with { $0 }
            guard !current.isLoading else {
                return
            }
            self.updateState { state in
                var state = state
                state.isLoading = true
                return state
            }

            var found: [Plugin] = []
            let fm = FileManager.default
            if let entries = try? fm.contentsOfDirectory(atPath: self.pluginsDirectory) {
                let enabled = self.loadEnabledIds()
                for entry in entries where entry.hasSuffix(".py") {
                    let id = (entry as NSString).deletingPathExtension
                    found.append(Plugin(
                        id: id,
                        path: self.pluginsDirectory + "/" + entry,
                        title: id,
                        description: "",
                        isEnabled: enabled.isEmpty || enabled.contains(id),
                        loadError: nil
                    ))
                }
            }

            self.updateState { state in
                var state = state
                state.plugins = found.sorted { $0.id < $1.id }
                state.isLoading = false
                return state
            }
            self.appendLog("discovered \(found.count) plugin(s)")
        }
    }

    /// Installs a `.py` file dropped from a chat message.
    @discardableResult
    public func installPlugin(at path: String) -> Bool {
        let fm = FileManager.default
        let name = (path as NSString).lastPathComponent
        guard name.hasSuffix(".py") else {
            self.appendLog("rejected \(name): not a .py plugin")
            return false
        }
        let destination = self.pluginsDirectory + "/" + name
        if fm.fileExists(atPath: destination) {
            try? fm.removeItem(atPath: destination)
        }
        do {
            try fm.copyItem(atPath: path, toPath: destination)
            self.appendLog("installed \(name)")
            self.reload()
            return true
        } catch {
            self.appendLog("install failed \(name): \(error.localizedDescription)")
            return false
        }
    }

    public func setPlugin(_ id: String, enabled: Bool) {
        self.updateState { state in
            var state = state
            if let index = state.plugins.firstIndex(where: { $0.id == id }) {
                state.plugins[index].isEnabled = enabled
            }
            return state
        }
        var enabledIds = self.loadEnabledIds()
        if enabled {
            enabledIds.insert(id)
        } else {
            enabledIds.remove(id)
        }
        self.saveEnabledIds(enabledIds)
        self.appendLog("\(enabled ? "enabled" : "disabled") \(id)")
    }

    // MARK: - Hooks

    public var hasEnabledPlugins: Bool {
        return self.stateValue.with { $0.plugins.contains(where: { $0.isEnabled }) }
    }

    /// Intercepts outgoing messages; returns `true` when a plugin cancelled sending.
    public func dispatchSendMessageHook(peerId: Any, messages: inout [Any]) -> Bool {
        guard self.hasEnabledPlugins, self.ensureInterpreter() else {
            return false
        }
        let text = messages.first.map { "\($0)" } ?? ""
        let enabled = self.stateValue.with { $0.plugins.filter { $0.isEnabled } }
        for plugin in enabled {
            let result = EmbeddedPython.shared.dispatchSendMessageHook(module: plugin.id, text: text)
            if result == 2 {
                self.appendLog("\(plugin.id) cancelled outgoing message")
                return true
            }
        }
        return false
    }

    // MARK: - Settings storage

    public func pluginDataDirectoryPath() -> String {
        return self.dataDirectory
    }

    public func settingsPath(forPlugin id: String) -> String {
        return self.dataDirectory + "/" + id + ".json"
    }

    public func loadSettings(forPlugin id: String) -> [String: Any] {
        guard let data = FileManager.default.contents(atPath: self.settingsPath(forPlugin: id)) else {
            return [:]
        }
        return (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
    }

    public func saveSettings(forPlugin id: String, values: [String: Any]) {
        guard JSONSerialization.isValidJSONObject(values),
              let data = try? JSONSerialization.data(withJSONObject: values, options: [.prettyPrinted]) else {
            return
        }
        try? data.write(to: URL(fileURLWithPath: self.settingsPath(forPlugin: id)))
    }

    private var enabledIdsPath: String {
        return self.dataDirectory + "/enabled.json"
    }

    private func loadEnabledIds() -> Set<String> {
        guard let data = FileManager.default.contents(atPath: self.enabledIdsPath),
              let list = try? JSONSerialization.jsonObject(with: data) as? [String] else {
            return []
        }
        return Set(list)
    }

    private func saveEnabledIds(_ ids: Set<String>) {
        guard let data = try? JSONSerialization.data(withJSONObject: Array(ids)) else {
            return
        }
        try? data.write(to: URL(fileURLWithPath: self.enabledIdsPath))
    }

    // MARK: - Logs

    private func appendLog(_ line: String) {
        let stamped = "[\(Self.timestamp())] \(line)"
        self.updateState { state in
            var state = state
            state.logs.append(stamped)
            if state.logs.count > 500 {
                state.logs.removeFirst(state.logs.count - 500)
            }
            return state
        }
    }

    public func clearLogs() {
        self.updateState { state in
            var state = state
            state.logs = []
            return state
        }
    }

    public var logs: [String] {
        return self.stateValue.with { $0.logs }
    }

    private func updateState(_ f: (State) -> State) {
        let updated = self.stateValue.modify(f)
        self.statePromise.set(updated)
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}
