import ISOInspectorKit
import XCTest

@testable import ISOInspectorApp

final class RandomAccessPayloadAnnotationProviderTests: XCTestCase {
    func testFallbackPropagatesCancellation() async throws {
        let provider = RandomAccessPayloadAnnotationProvider(
            reader: FailingReader(failure: .cancelled), registry: BoxParserRegistry(fallback: { _, _ in nil }))
        let header = try movieHeader()
        do {
            _ = try await provider.annotations(for: header)
            XCTFail("Expected cancellation")
        } catch is CancellationError {
        } catch {
            XCTFail("Expected cancellation, got \(error)")
        }
    }

    func testFallbackPropagatesReadFailure() async throws {
        let provider = RandomAccessPayloadAnnotationProvider(
            reader: FailingReader(failure: .io), registry: BoxParserRegistry(fallback: { _, _ in nil }))
        let header = try movieHeader()
        do {
            _ = try await provider.annotations(for: header)
            XCTFail("Expected the reader error")
        } catch FailingReader.Failure.io {
        } catch {
            XCTFail("Expected the reader error, got \(error)")
        }
    }

    func testFallbackReportsShortRead() async throws {
        let provider = RandomAccessPayloadAnnotationProvider(
            reader: ShortReader(), registry: BoxParserRegistry(fallback: { _, _ in nil }))
        do {
            _ = try await provider.annotations(for: movieHeader())
            XCTFail("Expected a truncated read error")
        } catch let error as RandomAccessReaderValueDecodingError {
            XCTAssertEqual(error, .truncatedRead(expected: 1, actual: 0))
        } catch {
            XCTFail("Expected a truncated read error, got \(error)")
        }
    }

    private func movieHeader() throws -> BoxHeader {
        BoxHeader(
            type: try FourCharCode("mvhd"), totalSize: 108, headerSize: 8,
            payloadRange: 8..<108, range: 0..<108, uuid: nil)
    }

    func testFileTypeAnnotations() async throws {
        var data = Data(repeating: 0x00, count: 8)
        data.append(contentsOf: [0x69, 0x73, 0x6F, 0x6D])  // isom
        data.append(contentsOf: [0x00, 0x00, 0x00, 0x01])  // minor version
        data.append(contentsOf: [0x61, 0x76, 0x63, 0x31])  // avc1
        data.append(contentsOf: [0x6D, 0x70, 0x34, 0x32])  // mp42

        let header = BoxHeader(
            type: try FourCharCode("ftyp"), totalSize: Int64(data.count), headerSize: 8,
            payloadRange: 8..<Int64(data.count), range: 0..<Int64(data.count), uuid: nil)
        let reader = InMemoryReader(data: data)
        let provider = RandomAccessPayloadAnnotationProvider(reader: reader)

        let annotations = try await provider.annotations(for: header)
        XCTAssertEqual(annotations.count, 4)
        XCTAssertEqual(annotations[0].label, "major_brand")
        XCTAssertEqual(annotations[0].value, "isom")
        XCTAssertEqual(annotations[0].byteRange, 8..<12)
        XCTAssertEqual(annotations[1].label, "minor_version")
        XCTAssertEqual(annotations[1].value, "1")
        XCTAssertEqual(annotations[1].byteRange, 12..<16)
        XCTAssertEqual(annotations[2].label, "compatible_brand[0]")
        XCTAssertEqual(annotations[2].value, "avc1")
        XCTAssertEqual(annotations[2].byteRange, 16..<20)
        XCTAssertEqual(annotations[3].label, "compatible_brand[1]")
        XCTAssertEqual(annotations[3].value, "mp42")
        XCTAssertEqual(annotations[3].byteRange, 20..<24)
    }

    func testMovieHeaderAnnotationsVersion0() async throws {
        var payload = Data()
        payload.append(contentsOf: [0x00])  // version
        payload.append(contentsOf: [0x00, 0x00, 0x01])  // flags
        payload.append(contentsOf: [0x00, 0x00, 0x00, 0x02])  // creation_time
        payload.append(contentsOf: [0x00, 0x00, 0x00, 0x03])  // modification_time
        payload.append(contentsOf: [0x00, 0x00, 0x03, 0xE8])  // timescale 1000
        payload.append(contentsOf: [0x00, 0x00, 0x00, 0x64])  // duration 100
        payload.append(contentsOf: [0x00, 0x01, 0x00, 0x00])  // rate 1.0
        payload.append(contentsOf: [0x01, 0x00])  // volume 1.0
        payload.append(contentsOf: Array(repeating: 0x00, count: 10))  // reserved
        payload.append(contentsOf: Array(repeating: 0x00, count: 36))  // matrix
        payload.append(contentsOf: Array(repeating: 0x00, count: 24))  // pre_defined
        payload.append(contentsOf: [0x00, 0x00, 0x00, 0x02])  // next_track_ID

        var data = Data(repeating: 0x00, count: 8)
        data.append(payload)

        let header = BoxHeader(
            type: try FourCharCode("mvhd"), totalSize: Int64(data.count), headerSize: 8,
            payloadRange: 8..<Int64(data.count), range: 0..<Int64(data.count), uuid: nil)
        let reader = InMemoryReader(data: data)
        let provider = RandomAccessPayloadAnnotationProvider(reader: reader)

        let annotations = try await provider.annotations(for: header)
        XCTAssertFalse(annotations.isEmpty)

        func annotation(_ label: String) -> PayloadAnnotation? {
            annotations.first { $0.label == label }
        }

        XCTAssertEqual(annotation("version")?.value, "0")
        XCTAssertEqual(annotation("version")?.byteRange, 8..<9)
        XCTAssertEqual(annotation("flags")?.value, "0x000001")
        XCTAssertEqual(annotation("flags")?.byteRange, 9..<12)
        XCTAssertEqual(annotation("creation_time")?.value, "2")
        XCTAssertEqual(annotation("creation_time")?.byteRange, 12..<16)
        XCTAssertEqual(annotation("timescale")?.value, "1000")
        XCTAssertEqual(annotation("timescale")?.byteRange, 20..<24)
        XCTAssertEqual(annotation("duration")?.value, "100")
        XCTAssertEqual(annotation("duration")?.byteRange, 24..<28)
        XCTAssertEqual(annotation("rate")?.value, "1.00")
        XCTAssertEqual(annotation("rate")?.byteRange, 28..<32)
        XCTAssertEqual(annotation("volume")?.value, "1.00")
        XCTAssertEqual(annotation("volume")?.byteRange, 32..<34)
        XCTAssertEqual(annotation("next_track_ID")?.value, "2")
        XCTAssertEqual(annotation("next_track_ID")?.byteRange, 104..<108)
    }
}

private struct FailingReader: RandomAccessReader {
    enum Failure: Error { case cancelled, io }
    let failure: Failure
    let length: Int64 = 108
    func read(at offset: Int64, count: Int) throws -> Data {
        switch failure {
        case .cancelled: throw CancellationError()
        case .io: throw Failure.io
        }
    }
}

private struct ShortReader: RandomAccessReader {
    let length: Int64 = 108
    func read(at offset: Int64, count: Int) throws -> Data { Data() }
}

private struct InMemoryReader: RandomAccessReader {
    let data: Data

    var length: Int64 { Int64(data.count) }

    func read(at offset: Int64, count: Int) throws -> Data {
        guard offset >= 0, count >= 0 else { throw NSError(domain: "InMemoryReader", code: 1) }
        let start = Int(offset)
        let upper = start + count
        guard start >= 0, upper <= data.count else {
            throw NSError(domain: "InMemoryReader", code: 2)
        }
        return data.subdata(in: start..<upper)
    }
}
