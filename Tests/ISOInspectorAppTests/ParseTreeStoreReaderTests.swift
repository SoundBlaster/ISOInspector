#if canImport(Combine)
    import Foundation
    import Testing

    @testable import ISOInspectorApp
    @testable import ISOInspectorKit

    @Suite struct ParseTreeStoreReaderTests {
        @Test @MainActor func startAndReplacementProvideTheCurrentReader() async throws {
            let store = ParseTreeStore()
            let (stream, continuation) = ParsePipeline.EventStream.makeStream()
            defer {
                continuation.finish()
                store.shutdown()
            }
            let pipeline = ParsePipeline(buildStream: { _, _ in stream })
            let header = BoxHeader(
                type: try FourCharCode("ftyp"), totalSize: 16, headerSize: 8,
                payloadRange: 8..<16, range: 0..<16, uuid: nil)
            let request = HexSliceRequest(header: header, window: .init(offset: 8, length: 4))
            let first = Data([0, 0, 0, 16, 0x66, 0x74, 0x79, 0x70, 0x69, 0x73, 0x6f, 0x6d, 0, 0, 0, 1])
            let second = Data([0, 0, 0, 16, 0x66, 0x74, 0x79, 0x70, 0x6d, 0x70, 0x34, 0x32, 0, 0, 0, 2])

            store.start(pipeline: pipeline, reader: InMemoryRandomAccessReader(data: first))
            let firstHex = try #require(store.makeHexSliceProvider())
            let firstAnnotations = try #require(store.makePayloadAnnotationProvider())
            #expect(try await firstHex.loadSlice(for: request).bytes == first.subdata(in: 8..<12))
            let firstAnnotation = try #require(await firstAnnotations.annotations(for: header).first)
            #expect(firstAnnotation.value == "isom")

            let (nextStream, nextContinuation) = ParsePipeline.EventStream.makeStream()
            defer { nextContinuation.finish() }
            store.start(
                pipeline: ParsePipeline(buildStream: { _, _ in nextStream }),
                reader: InMemoryRandomAccessReader(data: second))
            let secondHex = try #require(store.makeHexSliceProvider())
            let secondAnnotations = try #require(store.makePayloadAnnotationProvider())
            #expect(try await secondHex.loadSlice(for: request).bytes == second.subdata(in: 8..<12))
            let secondAnnotation = try #require(await secondAnnotations.annotations(for: header).first)
            #expect(secondAnnotation.value == "mp42")

            store.cancel()
            #expect(store.makeHexSliceProvider() == nil)
            #expect(store.makePayloadAnnotationProvider() == nil)
        }
    }
#endif
