import Foundation

public final class FilesystemAccessAuditTrail: @unchecked Sendable {
    private let limit: Int
    private let lock = NSLock()
    private var storage: [FilesystemAccessAuditEvent] = []

    public init(limit: Int = 100) { self.limit = max(0, limit) }

    public func append(_ event: FilesystemAccessAuditEvent) {
        guard limit > 0 else { return }
        lock.lock()
        storage.append(event)
        if storage.count > limit { storage.removeFirst(storage.count - limit) }
        lock.unlock()
    }

    public func snapshot() -> [FilesystemAccessAuditEvent] {
        lock.lock()
        let events = storage
        lock.unlock()
        return events
    }
}
