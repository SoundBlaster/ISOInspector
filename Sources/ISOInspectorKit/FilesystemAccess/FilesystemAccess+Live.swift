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
        securityScopeManager: any SecurityScopedAccessManaging =
            FoundationSecurityScopedAccessManager(),
        logger: FilesystemAccessLogger = .disabled,
        documentPickerPresenter: FilesystemDocumentPickerPresenter? = nil
    ) -> FilesystemAccess {
        #if canImport(AppKit)
            let openHandler: OpenFileHandler = { configuration in
                try await presentOpenPanel(configuration: configuration)
            }
            let saveHandler: SaveFileHandler = { configuration in
                try await presentSavePanel(configuration: configuration)
            }
        #elseif canImport(UIKit)
            let presenter = documentPickerPresenter ?? FilesystemDocumentPickerPresenter.uikit()
            let openHandler: OpenFileHandler = { configuration in
                try await presenter.open(configuration)
            }
            let saveHandler: SaveFileHandler = { configuration in
                try await presenter.save(configuration)
            }
        #else
            let openHandler: OpenFileHandler
            let saveHandler: SaveFileHandler
            if let presenter = documentPickerPresenter {
                openHandler = { configuration in
                    try await presenter.open(configuration)
                }
                saveHandler = { configuration in
                    try await presenter.save(configuration)
                }
            } else {
                openHandler = { _ in throw FilesystemAccessError.dialogUnavailable(dialog: .open) }
                saveHandler = { _ in throw FilesystemAccessError.dialogUnavailable(dialog: .save) }
            }
        #endif

        return FilesystemAccess(
            openFileHandler: openHandler,
            saveFileHandler: saveHandler,
            bookmarkCreator: bookmarkManager.createBookmark(for:),
            bookmarkResolver: bookmarkManager.resolveBookmark(data:),
            securityScopeManager: securityScopeManager,
            logger: logger
        )
    }
}

#if canImport(AppKit)
    extension FilesystemAccess {
        fileprivate static func presentOpenPanel(configuration: FilesystemOpenConfiguration)
            async throws -> URL
        {
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

        fileprivate static func presentSavePanel(configuration: FilesystemSaveConfiguration)
            async throws -> URL
        {
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

        @MainActor
        fileprivate static func applyAllowedContentTypes(
            _ identifiers: [String], to panel: NSOpenPanel
        ) {
            guard !identifiers.isEmpty else { return }
            guard #available(macOS 11.0, *), let types = makeUniformTypes(from: identifiers) else {
                return
            }
            panel.allowedContentTypes = types
        }

        @MainActor
        fileprivate static func applyAllowedContentTypes(
            _ identifiers: [String], to panel: NSSavePanel
        ) {
            guard !identifiers.isEmpty else { return }
            guard #available(macOS 11.0, *), let types = makeUniformTypes(from: identifiers) else {
                return
            }
            panel.allowedContentTypes = types
        }

        @available(macOS 11.0, *)
        fileprivate static func makeUniformTypes(from identifiers: [String]) -> [UTType]? {
            let types = identifiers.compactMap { UTType($0) }
            return types.isEmpty ? nil : types
        }
    }
#endif
