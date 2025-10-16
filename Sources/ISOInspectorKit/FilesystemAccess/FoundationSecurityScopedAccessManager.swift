import Foundation

/// Default implementation of `SecurityScopedAccessManaging` backed by `URL` security scope APIs.
public struct FoundationSecurityScopedAccessManager: SecurityScopedAccessManaging {
    public init() {}

    public func startAccessing(_ url: URL) -> Bool {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        return url.startAccessingSecurityScopedResource()
        #else
        return true
        #endif
    }

    public func stopAccessing(_ url: URL) {
        #if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)
        url.stopAccessingSecurityScopedResource()
        #endif
    }
}
