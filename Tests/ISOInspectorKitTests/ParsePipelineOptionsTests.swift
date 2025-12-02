import Foundation
import XCTest

@testable import ISOInspectorKit

final class ParsePipelineOptionsTests: XCTestCase {
    func testStrictDefaultsMatchExpectations() {
        let options = ParsePipeline.Options.strict

        XCTAssertTrue(options.abortOnStructuralError)
        XCTAssertEqual(options.maxCorruptionEvents, 0)
        XCTAssertEqual(options.payloadValidationLevel, .full)
        XCTAssertEqual(options.maxTraversalDepth, 64)
        XCTAssertEqual(options.maxStalledIterationsPerFrame, 3)
        XCTAssertEqual(options.maxZeroLengthBoxesPerParent, 2)
        XCTAssertEqual(options.maxIssuesPerFrame, 256)
    }

    func testTolerantDefaultsMatchExpectations() {
        let options = ParsePipeline.Options.tolerant

        XCTAssertFalse(options.abortOnStructuralError)
        XCTAssertEqual(options.maxCorruptionEvents, 500)
        XCTAssertEqual(options.payloadValidationLevel, .structureOnly)
        XCTAssertEqual(options.maxTraversalDepth, 64)
        XCTAssertEqual(options.maxStalledIterationsPerFrame, 3)
        XCTAssertEqual(options.maxZeroLengthBoxesPerParent, 2)
        XCTAssertEqual(options.maxIssuesPerFrame, 256)
    }

    func testPipelineAppliesDefaultOptionsWhenContextUsesAutomaticSettings() {
        let recorder = OptionsRecorder()
        let pipeline = ParsePipeline(options: .tolerant) { _, context in
            recorder.record(context.options)
            return AsyncThrowingStream { continuation in continuation.finish() }
        }

        _ = pipeline.events(for: InMemoryRandomAccessReader(data: Data()))

        XCTAssertEqual(recorder.value, .tolerant)
    }

    func testContextCanOverridePipelineOptions() {
        let recorder = OptionsRecorder()
        let pipeline = ParsePipeline(options: .tolerant) { _, context in
            recorder.record(context.options)
            return AsyncThrowingStream { continuation in continuation.finish() }
        }

        let context = ParsePipeline.Context(options: .strict)
        _ = pipeline.events(for: InMemoryRandomAccessReader(data: Data()), context: context)

        XCTAssertEqual(recorder.value, .strict)
    }
}

private final class OptionsRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: ParsePipeline.Options?

    func record(_ value: ParsePipeline.Options) {
        lock.lock()
        storage = value
        lock.unlock()
    }

    var value: ParsePipeline.Options? {
        lock.lock()
        let value = storage
        lock.unlock()
        return value
    }
}
