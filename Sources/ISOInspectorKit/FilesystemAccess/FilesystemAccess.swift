import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Entry point for requesting user-authorised filesystem access across ISOInspector targets.
public struct FilesystemAccess: Sendable {
    public typealias OpenFileHandler = @Sendable (FilesystemOpenConfiguration) async throws -> URL
    public typealias SaveFileHandler = @Sendable (FilesystemSaveConfiguration) async throws -> URL
    public typealias BookmarkCreator = @Sendable (URL) throws -> Data
    public typealias BookmarkResolver = @Sendable (Data) throws -> BookmarkResolution

    private let openFileHandler: OpenFileHandler
    private let saveFileHandler: SaveFileHandler
    private let bookmarkCreator: BookmarkCreator
    private let bookmarkResolver: BookmarkResolver
    private let securityScopeManager: any SecurityScopedAccessManaging
    private let logger: FilesystemAccessLogger

    public init(
        openFileHandler: @escaping OpenFileHandler,
        saveFileHandler: @escaping SaveFileHandler,
        bookmarkCreator: @escaping BookmarkCreator,
        bookmarkResolver: @escaping BookmarkResolver,
        securityScopeManager: any SecurityScopedAccessManaging,
        logger: FilesystemAccessLogger = .disabled
    ) {
        self.openFileHandler = openFileHandler
        self.saveFileHandler = saveFileHandler
        self.bookmarkCreator = bookmarkCreator
        self.bookmarkResolver = bookmarkResolver
        self.securityScopeManager = securityScopeManager
        self.logger = logger
    }

    /// Presents an open-file dialog and returns a security-scoped URL for the user's selection.
    public func openFile(
        configuration: FilesystemOpenConfiguration = FilesystemOpenConfiguration()
    ) async throws -> SecurityScopedURL {
        let selectedURL = try await openFileHandler(configuration)
        return try activateSecurityScope(for: selectedURL, category: .openFile)
    }

    /// Presents a save-file dialog and returns a security-scoped URL for the destination.
    public func saveFile(
        configuration: FilesystemSaveConfiguration
    ) async throws -> SecurityScopedURL {
        let destination = try await saveFileHandler(configuration)
        return try activateSecurityScope(for: destination, category: .saveFile)
    }

    /// Creates bookmark data for the provided security-scoped URL.
    public func createBookmark(for scopedURL: SecurityScopedURL) throws -> Data {
        do {
            let data = try bookmarkCreator(scopedURL.url)
            let pathHash = hashIdentifier(for: scopedURL.url)
            logger.log(
                category: .bookmarkCreate,
                outcome: .success,
                pathHash: pathHash
            )
            return data
        } catch {
            logger.log(
                category: .bookmarkCreate,
                outcome: .failure,
                errorDescription: sanitisedDescription(for: error)
            )
            throw FilesystemAccessError.bookmarkCreationFailed(underlying: error)
        }
    }

    /// Resolves bookmark data, returning an active security-scoped URL and stale-state flag.
    public func resolveBookmarkData(_ data: Data) throws -> ResolvedSecurityScopedURL {
        do {
            let resolution = try bookmarkResolver(data)
            let scoped = try activateSecurityScope(for: resolution.url, category: .bookmarkResolve)
            if resolution.isStale {
                logger.log(
                    category: .bookmarkResolve,
                    outcome: .stale,
                    pathHash: hashIdentifier(for: resolution.url)
                )
            } else {
                logger.log(
                    category: .bookmarkResolve,
                    outcome: .success,
                    pathHash: hashIdentifier(for: resolution.url)
                )
            }
            return ResolvedSecurityScopedURL(url: scoped, isStale: resolution.isStale)
        } catch {
            logger.log(
                category: .bookmarkResolve,
                outcome: .failure,
                errorDescription: sanitisedDescription(for: error)
            )
            throw FilesystemAccessError.bookmarkResolutionFailed(underlying: error)
        }
    }

    private func activateSecurityScope(
        for url: URL,
        category: FilesystemAccessAuditEvent.Category
    ) throws -> SecurityScopedURL {
        let standardized = url.standardizedFileURL
        let pathHash = hashIdentifier(for: standardized)
        guard securityScopeManager.startAccessing(standardized) else {
            logger.log(
                category: category,
                outcome: .authorizationDenied,
                pathHash: pathHash
            )
            throw FilesystemAccessError.authorizationDenied(url: standardized)
        }
        logger.log(
            category: category,
            outcome: .accessGranted,
            pathHash: pathHash
        )
        return SecurityScopedURL(url: standardized, manager: securityScopeManager)
    }

    private func hashIdentifier(for url: URL) -> String {
        let path = url.standardizedFileURL.path
        #if canImport(CryptoKit)
        let digest = SHA256.hash(data: Data(path.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
        #else
        var hasher = Hasher()
        hasher.combine(path)
        return String(hasher.finalize())
        #endif
    }

    private func sanitisedDescription(for error: Error) -> String {
        if let cocoa = error as? CocoaError {
            return "CocoaError.\(cocoa.code.rawValue)"
        }
        return String(describing: error)
    }
}
