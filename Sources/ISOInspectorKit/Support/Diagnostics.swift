import Foundation

#if canImport(os)
    import os
#endif

public protocol DiagnosticsLogging: Sendable {
    func info(_ message: String)
    func error(_ message: String)
}

public struct DiagnosticsLogger: DiagnosticsLogging {
    #if canImport(os)
        private let wrapped: Logger
    #else
        private let label: String
    #endif

    public init(subsystem: String, category: String) {
        #if canImport(os)
            self.wrapped = Logger(subsystem: subsystem, category: category)
        #else
            self.label = "[\(subsystem)] \(category)"
        #endif
    }

    public func info(_ message: String) {
        #if canImport(os)
            wrapped.info("\(message, privacy: .public)")
        #else
            print("INFO \(label): \(message)")
        #endif
    }

    public func error(_ message: String) {
        #if canImport(os)
            wrapped.error("\(message, privacy: .public)")
        #else
            let line = "ERROR \(label): \(message)\n"
            FileHandle.standardError.write(Data(line.utf8))
        #endif
    }
}
