import Foundation
import UIKit
import SwiftSignalKit
import AccountContext
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import UndoUI
import PythonPlugins

private enum TrollPluginsSection: Int32 {
    case install
    case plugins
    case logs
}

private enum TrollPluginsEntry: ItemListNodeEntry {
    case header(id: Int32, text: String)
    case notice(id: Int32, text: String)
    case plugin(id: Int32, plugin: PythonPluginManager.Plugin)
    case logs(id: Int32, text: String)
    case clearLogs(id: Int32, text: String)

    var section: ItemListSectionId {
        switch self {
        case .header, .notice:
            return TrollPluginsSection.install.rawValue
        case .plugin:
            return TrollPluginsSection.plugins.rawValue
        case .logs, .clearLogs:
            return TrollPluginsSection.logs.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case let .header(id, _), let .notice(id, _), let .plugin(id, _), let .logs(id, _), let .clearLogs(id, _):
            return id
        }
    }

    static func <(lhs: TrollPluginsEntry, rhs: TrollPluginsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! TrollPluginsArguments
        switch self {
        case let .header(_, text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .notice(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .plugin(_, plugin):
            return ItemListSwitchItem(
                presentationData: presentationData,
                title: plugin.title,
                value: plugin.isEnabled,
                enableInteractiveTransitioning: false,
                sectionId: self.section,
                style: .blocks,
                updated: { value in
                    arguments.togglePlugin(plugin.id, value)
                }
            )
        case let .logs(_, text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .clearLogs(_, text):
            return ItemListDisclosureItem(
                presentationData: presentationData,
                title: text,
                label: "",
                sectionId: self.section,
                style: .blocks,
                action: {
                    arguments.clearLogs()
                }
            )
        }
    }
}

private final class TrollPluginsArguments {
    let context: AccountContext
    let togglePlugin: (String, Bool) -> Void
    let clearLogs: () -> Void

    init(context: AccountContext, togglePlugin: @escaping (String, Bool) -> Void, clearLogs: @escaping () -> Void) {
        self.context = context
        self.togglePlugin = togglePlugin
        self.clearLogs = clearLogs
    }
}

public func trollPluginsController(context: AccountContext) -> ViewController {
    let initialState = PythonPluginManager.shared.state
    PythonPluginManager.shared.reload()

    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let arguments = TrollPluginsArguments(
        context: context,
        togglePlugin: { id, enabled in
            PythonPluginManager.shared.setPlugin(id, enabled: enabled)
        },
        clearLogs: {
            PythonPluginManager.shared.clearLogs()
        }
    )

    let signal = initialState
    |> deliverOnMainQueue
    |> map { state -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let strings = context.sharedContext.currentPresentationData.with { $0 }.strings

        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("TrollGram Plugins"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: strings.Common_Back)
        )

        var entries: [TrollPluginsEntry] = []
        var id: Int32 = 0
        func nextId() -> Int32 {
            id += 1
            return id
        }

        entries.append(.header(id: nextId(), text: "PLUGINS DIRECTORY"))
        entries.append(.notice(id: nextId(), text: PythonPluginManager.shared.pluginsDirectoryPath))

        entries.append(.header(id: nextId(), text: "INSTALLED (\(state.plugins.count))"))
        if state.plugins.isEmpty {
            entries.append(.notice(id: nextId(), text: "No plugins. Send a .py file to any chat and tap it to install."))
        } else {
            for plugin in state.plugins {
                entries.append(.plugin(id: nextId(), plugin: plugin))
            }
        }

        entries.append(.header(id: nextId(), text: "LOGGER"))
        let logText = state.logs.isEmpty ? "No entries." : state.logs.suffix(40).joined(separator: "\n")
        entries.append(.logs(id: nextId(), text: logText))
        entries.append(.clearLogs(id: nextId(), text: "Clear Log"))

        let nodeState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: entries, style: .blocks)
        return (controllerState, (nodeState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    return controller
}
