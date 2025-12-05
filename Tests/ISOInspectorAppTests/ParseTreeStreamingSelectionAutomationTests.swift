#if canImport(AppKit) && canImport(SwiftUI) && canImport(Combine)
    import AppKit
    import Combine
    import SwiftUI
    import XCTest
    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    @MainActor final class ParseTreeStreamingSelectionAutomationTests: XCTestCase {
        func testStreamingSessionAppliesDefaultSelection() throws {
            throw XCTSkip("UI automation requires an interactive AppKit host")
        }
    }

    private struct StubReader: RandomAccessReader {
        let data: Data

        var length: Int64 { Int64(data.count) }

        func read(at offset: Int64, count: Int) throws -> Data {
            let lower = max(0, min(Int(offset), data.count))
            let upper = min(data.count, lower + count)
            return data.subdata(in: lower..<upper)
        }
    }
#endif
