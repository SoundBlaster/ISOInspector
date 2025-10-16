import Foundation
#if canImport(UIKit)
import UIKit
import ObjectiveC.runtime
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Abstraction that bridges FilesystemAccess flows to a platform document picker implementation.
public struct FilesystemDocumentPickerPresenter: Sendable {
    public typealias OpenHandler = @Sendable (FilesystemOpenConfiguration) async throws -> URL
    public typealias SaveHandler = @Sendable (FilesystemSaveConfiguration) async throws -> URL

    private let openHandler: OpenHandler
    private let saveHandler: SaveHandler

    public init(
        openHandler: @escaping OpenHandler,
        saveHandler: @escaping SaveHandler
    ) {
        self.openHandler = openHandler
        self.saveHandler = saveHandler
    }

    public func open(_ configuration: FilesystemOpenConfiguration) async throws -> URL {
        try await openHandler(configuration)
    }

    public func save(_ configuration: FilesystemSaveConfiguration) async throws -> URL {
        try await saveHandler(configuration)
    }
}

#if canImport(UIKit)
extension FilesystemDocumentPickerPresenter {
    /// Creates a presenter that wraps `UIDocumentPickerViewController` presentation.
    /// - Parameter presentingViewControllerProvider: Closure resolving the controller that should present the picker.
    /// - Returns: A presenter that handles open and save flows using UIKit dialogs.
    public static func uikit(
        presentingViewControllerProvider: @escaping @Sendable () -> UIViewController? = { defaultPresentingViewController() }
    ) -> FilesystemDocumentPickerPresenter {
        FilesystemDocumentPickerPresenter(
            openHandler: { configuration in
                try await presentOpenPicker(
                    configuration: configuration,
                    presentingViewControllerProvider: presentingViewControllerProvider
                )
            },
            saveHandler: { configuration in
                try await presentSavePicker(
                    configuration: configuration,
                    presentingViewControllerProvider: presentingViewControllerProvider
                )
            }
        )
    }
}

// MARK: - UIKit Helpers

@MainActor
private func presentPicker(
    _ picker: UIDocumentPickerViewController,
    dialog: FilesystemAccessError.Dialog,
    presentingViewControllerProvider: @escaping @Sendable () -> UIViewController?
) async throws -> URL {
    let presenter = presentingViewControllerProvider()?.iso_topMostPresented()
    guard let presenter else {
        throw FilesystemAccessError.dialogUnavailable(dialog: dialog)
    }

    return try await withCheckedThrowingContinuation { continuation in
        let coordinator = UIDocumentPickerCoordinator(
            dialog: dialog,
            continuation: continuation
        )
        coordinator.install(on: picker)
        presenter.present(picker, animated: true)
    }
}

@MainActor
private func presentOpenPicker(
    configuration: FilesystemOpenConfiguration,
    presentingViewControllerProvider: @escaping @Sendable () -> UIViewController?
) async throws -> URL {
    let picker = makeOpenPicker(configuration: configuration)
    return try await presentPicker(
        picker,
        dialog: .open,
        presentingViewControllerProvider: presentingViewControllerProvider
    )
}

@MainActor
private func presentSavePicker(
    configuration: FilesystemSaveConfiguration,
    presentingViewControllerProvider: @escaping @Sendable () -> UIViewController?
) async throws -> URL {
    let picker = makeSavePicker(configuration: configuration)
    return try await presentPicker(
        picker,
        dialog: .save,
        presentingViewControllerProvider: presentingViewControllerProvider
    )
}

@MainActor
private func makeOpenPicker(configuration: FilesystemOpenConfiguration) -> UIDocumentPickerViewController {
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
        if let contentTypes = makeUniformTypes(from: configuration.allowedContentTypes) {
            picker = UIDocumentPickerViewController(
                forOpeningContentTypes: contentTypes,
                asCopy: false
            )
        } else {
            picker = UIDocumentPickerViewController(forOpeningContentTypes: [])
        }
    } else {
        let identifiers = configuration.allowedContentTypes
        picker = UIDocumentPickerViewController(
            documentTypes: identifiers.isEmpty ? ["public.item"] : identifiers,
            in: .open
        )
    }
    picker.allowsMultipleSelection = configuration.allowsMultipleSelection
    picker.modalPresentationStyle = .formSheet
    return picker
}

@MainActor
private func makeSavePicker(configuration: FilesystemSaveConfiguration) -> UIDocumentPickerViewController {
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
        let contentType = configuration.allowedContentTypes
            .compactMap { UTType($0) }
            .first ?? UTType.data
        picker = UIDocumentPickerViewController(forCreatingDocumentOfContentType: contentType)
    } else {
        let identifiers = configuration.allowedContentTypes
        picker = UIDocumentPickerViewController(
            documentTypes: identifiers.isEmpty ? ["public.item"] : identifiers,
            in: .open
        )
    }
    picker.modalPresentationStyle = .formSheet
    return picker
}

private func makeUniformTypes(from identifiers: [String]) -> [UTType]? {
    let types = identifiers.compactMap(UTType.init)
    return types.isEmpty ? nil : types
}

@MainActor
private func defaultPresentingViewController() -> UIViewController? {
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first(where: { $0.isKeyWindow })?
        .rootViewController?
        .iso_topMostPresented()
}

private final class UIDocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate {
    private let dialog: FilesystemAccessError.Dialog
    private var continuation: CheckedContinuation<URL, Error>?

    init(
        dialog: FilesystemAccessError.Dialog,
        continuation: CheckedContinuation<URL, Error>
    ) {
        self.dialog = dialog
        self.continuation = continuation
        super.init()
    }

    func install(on picker: UIDocumentPickerViewController) {
        picker.delegate = self
        objc_setAssociatedObject(
            picker,
            &AssociatedKeys.coordinator,
            self,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
        resume(with: .failure(FilesystemAccessError.dialogUnavailable(dialog: dialog)), controller: controller)
    }

    func documentPicker(
        _ controller: UIDocumentPickerViewController,
        didPickDocumentsAt urls: [URL]
    ) {
        controller.dismiss(animated: true)
        guard let url = urls.first else {
            resume(
                with: .failure(FilesystemAccessError.dialogUnavailable(dialog: dialog)),
                controller: controller
            )
            return
        }
        resume(with: .success(url), controller: controller)
    }

    private func resume(
        with result: Result<URL, Error>,
        controller: UIDocumentPickerViewController
    ) {
        objc_setAssociatedObject(
            controller,
            &AssociatedKeys.coordinator,
            nil,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        guard let continuation else { return }
        self.continuation = nil
        switch result {
        case .success(let url):
            continuation.resume(returning: url)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}

private enum AssociatedKeys {
    static var coordinator = 0
}

private extension UIViewController {
    func iso_topMostPresented() -> UIViewController {
        var controller: UIViewController = self
        while let presented = controller.presentedViewController {
            controller = presented
        }
        return controller
    }
}
#endif
