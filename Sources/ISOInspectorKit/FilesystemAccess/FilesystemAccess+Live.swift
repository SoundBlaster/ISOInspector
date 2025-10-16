import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

extension FilesystemAccess {
    /// Returns the default implementation that bridges to platform-specific dialogs and Foundation bookmark helpers.
    public static func live(
        bookmarkManager: BookmarkDataManaging = FoundationBookmarkDataManager(),
        securityScopeManager: any SecurityScopedAccessManaging = FoundationSecurityScopedAccessManager(),
        logger: FilesystemAccessLogger = .disabled
    ) -> FilesystemAccess {
        FilesystemAccess(
            openFileHandler: { configuration in
                #if canImport(AppKit)
                return try await presentOpenPanel(configuration: configuration)
                #else
                // @todo PDD:1h Provide UIDocumentPicker integration for iOS/iPadOS once UIKit adapters are introduced.
                throw FilesystemAccessError.dialogUnavailable(dialog: .open)
                #endif
            },
            saveFileHandler: { configuration in
                #if canImport(AppKit)
                return try await presentSavePanel(configuration: configuration)
                #else
                // @todo PDD:1h Provide UIDocumentPicker integration for iOS/iPadOS once UIKit adapters are introduced.
                throw FilesystemAccessError.dialogUnavailable(dialog: .save)
                #endif
            },
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: securityScopeManager,
            logger: logger
        )
    }
}

#if canImport(AppKit)
private extension FilesystemAccess {
    static func presentOpenPanel(configuration: FilesystemOpenConfiguration) async throws -> URL {
        try await MainActor.run {
            let panel = NSOpenPanel()
            panel.canChooseFiles = true
            panel.canChooseDirectories = false
            panel.allowsMultipleSelection = configuration.allowsMultipleSelection
            applyAllowedContentTypes(configuration.allowedContentTypes, to: panel)
            let result = panel.runModal()
            guard result == .OK, let url = panel.urls.first else {
                throw FilesystemAccessError.dialogUnavailable(dialog: .open)
            }
            return url
        }
    }

    static func presentSavePanel(configuration: FilesystemSaveConfiguration) async throws -> URL {
        try await MainActor.run {
            let panel = NSSavePanel()
            applyAllowedContentTypes(configuration.allowedContentTypes, to: panel)
            panel.nameFieldStringValue = configuration.suggestedFilename ?? ""
            let result = panel.runModal()
            guard result == .OK, let url = panel.url else {
                throw FilesystemAccessError.dialogUnavailable(dialog: .save)
            }
            return url
        }
    }

    static func applyAllowedContentTypes(_ identifiers: [String], to panel: NSOpenPanel) {
        guard !identifiers.isEmpty else { return }
        if #available(macOS 11.0, *), let types = makeUniformTypes(from: identifiers) {
            panel.allowedContentTypes = types
        } else {
            panel.allowedFileTypes = identifiers
        }
    }

    static func applyAllowedContentTypes(_ identifiers: [String], to panel: NSSavePanel) {
        guard !identifiers.isEmpty else { return }
        if #available(macOS 11.0, *), let types = makeUniformTypes(from: identifiers) {
            panel.allowedContentTypes = types
        } else {
            panel.allowedFileTypes = identifiers
        }
    }

    @available(macOS 11.0, *)
    static func makeUniformTypes(from identifiers: [String]) -> [UTType]? {
        let types = identifiers.compactMap { UTType($0) }
        return types.isEmpty ? nil : types
    }
}
#endif
