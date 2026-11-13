import Foundation
import UIKit
import TelegramPresentationData
import UniformTypeIdentifiers
import AccountContext
import PythonPlugins

public final class PythonPluginsInstaller {
    private weak var presentedController: UIViewController?

    public init() {}

    /// Presents a Files picker filtered to `.py` and installs the selection.
    public func present(from context: AccountContext, presenter: @escaping (UIViewController) -> Void) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pythonScript], asCopy: true)
        picker.allowsMultipleSelection = true
        picker.shouldShowFileExtensions = true

        let delegate = PickerDelegate(onPick: { urls in
            for url in urls {
                _ = PythonPluginManager.shared.installPlugin(at: url.path)
            }
        }, onController: { [weak self] controller in
            self?.presentedController = controller
        })
        picker.delegate = delegate
        self.delegate = delegate
        presenter(picker)
    }

    private var delegate: PickerDelegate?
}

extension UTType {
    public static var pythonScript: UTType {
        return UTType(filenameExtension: "py") ?? .plainText
    }
}

private final class PickerDelegate: NSObject, UIDocumentPickerDelegate {
    private let onPick: ([URL]) -> Void
    private let onController: (UIViewController) -> Void

    init(onPick: @escaping ([URL]) -> Void, onController: @escaping (UIViewController) -> Void) {
        self.onPick = onPick
        self.onController = onController
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        self.onController(controller)
        self.onPick(urls)
    }
}
