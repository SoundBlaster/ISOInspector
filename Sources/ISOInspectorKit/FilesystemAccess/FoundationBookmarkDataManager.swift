import Foundation

/// Default `BookmarkDataManaging` implementation that leverages Foundation bookmark APIs.
public struct FoundationBookmarkDataManager: BookmarkDataManaging {
    #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
    private let creationOptions: URL.BookmarkCreationOptions
    private let resolutionOptions: URL.BookmarkResolutionOptions

    public init(
        creationOptions: URL.BookmarkCreationOptions = Self.defaultCreationOptions(),
        resolutionOptions: URL.BookmarkResolutionOptions = Self.defaultResolutionOptions()
    ) {
        self.creationOptions = creationOptions
        self.resolutionOptions = resolutionOptions
    }
    #else
    public init() {}
    #endif

    public func createBookmark(for url: URL) throws -> Data {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return try url.bookmarkData(options: creationOptions)
        #else
        return Data(url.path.utf8)
        #endif
    }

    public func resolveBookmark(data: Data) throws -> BookmarkResolution {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        var isStale = false
        let resolved = try URL(
            resolvingBookmarkData: data,
            options: resolutionOptions,
            bookmarkDataIsStale: &isStale
        )
        return BookmarkResolution(url: resolved, isStale: isStale)
        #else
        guard let path = String(data: data, encoding: .utf8) else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return BookmarkResolution(url: URL(fileURLWithPath: path), isStale: false)
        #endif
    }
}

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
extension FoundationBookmarkDataManager {
    @usableFromInline
    static func defaultCreationOptions() -> URL.BookmarkCreationOptions {
        #if os(macOS)
        return [.withSecurityScope]
        #else
        return []
        #endif
    }

    @usableFromInline
    static func defaultResolutionOptions() -> URL.BookmarkResolutionOptions {
        #if os(macOS)
        return [.withSecurityScope]
        #else
        return []
        #endif
    }
}
#endif
