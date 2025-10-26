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
    #if canImport(UIKit)
    public typealias PresentingViewControllerProvider = @MainActor @Sendable () -> UIViewController?
    #endif

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
        presentingViewControllerProvider: PresentingViewControllerProvider? = nil
    ) -> FilesystemDocumentPickerPresenter {
        let provider = presentingViewControllerProvider ?? defaultPresentingViewControllerProvider()
        return FilesystemDocumentPickerPresenter(
            openHandler: { configuration in
                try await presentOpenPicker(
                    configuration: configuration,
                    presentingViewControllerProvider: provider
                )
            },
            saveHandler: { configuration in
                try await presentSavePicker(
                    configuration: configuration,
                    presentingViewControllerProvider: provider
                )
            }
        )
    }

    private static func defaultPresentingViewControllerProvider()
        -> PresentingViewControllerProvider {
        { defaultPresentingViewController() }
    }
}

// MARK: - UIKit Helpers

@MainActor
private func presentPicker(
    _ picker: UIDocumentPickerViewController,
    dialog: FilesystemAccessError.Dialog,
    presentingViewControllerProvider: FilesystemDocumentPickerPresenter.PresentingViewControllerProvider
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
    presentingViewControllerProvider: FilesystemDocumentPickerPresenter.PresentingViewControllerProvider
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
    presentingViewControllerProvider: FilesystemDocumentPickerPresenter.PresentingViewControllerProvider
) async throws -> URL {
    let payload = try makeSavePicker(configuration: configuration)
    defer {
        if let placeholder = payload.placeholderURL {
            cleanupPlaceholder(at: placeholder)
        }
    }
    return try await presentPicker(
        payload.picker,
        dialog: .save,
        presentingViewControllerProvider: presentingViewControllerProvider
    )
}

@MainActor
private func makeOpenPicker(configuration: FilesystemOpenConfiguration) -> UIDocumentPickerViewController {
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, macCatalyst 14.0, *) {
        let contentTypes = makeUniformTypes(from: configuration.allowedContentTypes) ?? [UTType.item]
        picker = UIDocumentPickerViewController(
            forOpeningContentTypes: contentTypes,
            asCopy: false
        )
    } else {
        let identifiers = configuration.allowedContentTypes
        picker = UIDocumentPickerViewController(
            documentTypes: identifiers.isEmpty ? ["public.item"] : identifiers,
            in: .open
        )
    }
    picker.allowsMultipleSelection = configuration.allowsMultipleSelection
    picker.modalPresentationStyle = UIModalPresentationStyle.formSheet
    return picker
}

@MainActor
private func makeSavePicker(configuration: FilesystemSaveConfiguration) throws -> SavePickerPayload {
    if #available(iOS 14.0, macCatalyst 14.0, *) {
        let contentType = configuration.allowedContentTypes
            .compactMap { UTType($0) }
            .first ?? UTType.data
        let filename = resolveFilename(
            suggested: configuration.suggestedFilename,
            contentType: contentType
        )
        let placeholder = try createPlaceholderFile(named: filename)
        let picker = UIDocumentPickerViewController(
            forExporting: [placeholder],
            asCopy: true
        )
        picker.modalPresentationStyle = UIModalPresentationStyle.formSheet
        return SavePickerPayload(picker: picker, placeholderURL: placeholder)
    } else {
        let identifiers = configuration.allowedContentTypes
        let picker = UIDocumentPickerViewController(
            documentTypes: identifiers.isEmpty ? ["public.item"] : identifiers,
            in: .open
        )
        picker.modalPresentationStyle = UIModalPresentationStyle.formSheet
        return SavePickerPayload(picker: picker, placeholderURL: nil)
    }
}

private func makeUniformTypes(from identifiers: [String]) -> [UTType]? {
    let types = identifiers.compactMap(UTType.init)
    return types.isEmpty ? nil : types
}

private struct SavePickerPayload {
    let picker: UIDocumentPickerViewController
    let placeholderURL: URL?
}

private func resolveFilename(
    suggested: String?,
    contentType: UTType
) -> String {
    let fallback = "Untitled"
    let trimmed = suggested?.trimmingCharacters(in: .whitespacesAndNewlines)
    let base = (trimmed?.isEmpty ?? true) ? fallback : trimmed!
    guard let preferredExtension = contentType.preferredFilenameExtension else {
        return base
    }
    let existingExtension = (base as NSString).pathExtension
    if !existingExtension.isEmpty || base.lowercased().hasSuffix(".\(preferredExtension.lowercased())") {
        return base
    }
    return base + "." + preferredExtension
}

private func createPlaceholderFile(named filename: String) throws -> URL {
    let manager = FileManager.default
    let root = manager.temporaryDirectory.appendingPathComponent(
        "FilesystemSavePlaceholders",
        isDirectory: true
    )
    try manager.createDirectory(at: root, withIntermediateDirectories: true, attributes: nil)
    let workingDirectory = root.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try manager.createDirectory(at: workingDirectory, withIntermediateDirectories: true, attributes: nil)
    let placeholderURL = workingDirectory.appendingPathComponent(filename, isDirectory: false)
    let created = manager.createFile(atPath: placeholderURL.path, contents: Data())
    guard created else {
        throw FilesystemAccessError.dialogUnavailable(dialog: .save)
    }
    return placeholderURL
}

private func cleanupPlaceholder(at url: URL) {
    let manager = FileManager.default
    try? manager.removeItem(at: url)
    let directory = url.deletingLastPathComponent()
    try? manager.removeItem(at: directory)
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
