import Foundation

#if canImport(os)
import os
#endif

struct DiagnosticsLogger {
    #if canImport(os)
    private let wrapped: Logger
    #else
    private let label: String
    #endif

    init(subsystem: String, category: String) {
        #if canImport(os)
        self.wrapped = Logger(subsystem: subsystem, category: category)
        #else
        self.label = "[\(subsystem)] \(category)"
        #endif
    }

    func info(_ message: String) {
        #if canImport(os)
        wrapped.info("\(message, privacy: .public)")
        #else
        print("INFO \(label): \(message)")
        #endif
    }

    func error(_ message: String) {
        #if canImport(os)
        wrapped.error("\(message, privacy: .public)")
        #else
        fputs("ERROR \(label): \(message)\n", stderr)
        #endif
    }
}
