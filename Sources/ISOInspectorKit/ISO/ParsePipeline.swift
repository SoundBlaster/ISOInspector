import Foundation

public struct ParseEvent: Equatable, Sendable {
    public enum Kind: Equatable, Sendable {
        case willStartBox(header: BoxHeader, depth: Int)
        case didFinishBox(header: BoxHeader, depth: Int)
    }

    public let kind: Kind
    public let offset: Int64

    public init(kind: Kind, offset: Int64) {
        self.kind = kind
        self.offset = offset
    }
}

public struct ParsePipeline: Sendable {
    public typealias EventStream = AsyncThrowingStream<ParseEvent, Error>
    public typealias Builder = @Sendable (_ reader: RandomAccessReader) -> EventStream

    private let buildStream: Builder

    public init(buildStream: @escaping Builder) {
        self.buildStream = buildStream
    }

    public init(_ buildStream: @escaping Builder) {
        self.buildStream = buildStream
    }

    public func events(for reader: RandomAccessReader) -> EventStream {
        buildStream(reader)
    }
}

public extension ParsePipeline {
    static func live() -> ParsePipeline {
        ParsePipeline(buildStream: { reader in
            AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        try process(reader: reader, continuation: continuation)
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }

                continuation.onTermination = { @Sendable _ in
                    task.cancel()
                }
            }
        })
    }

    private struct Frame {
        let header: BoxHeader?
        let range: Range<Int64>
        var cursor: Int64
        let depth: Int
        let shouldParseChildren: Bool
    }

    private static func process(
        reader: RandomAccessReader,
        continuation: AsyncThrowingStream<ParseEvent, Error>.Continuation
    ) throws {
        var stack: [Frame] = [Frame(
            header: nil,
            range: Int64(0)..<reader.length,
            cursor: Int64(0),
            depth: -1,
            shouldParseChildren: true
        )]

        while let frame = stack.last {
            try Task.checkCancellation()

            if !frame.shouldParseChildren || frame.cursor >= frame.range.upperBound {
                let finished = stack.removeLast()
                if let header = finished.header {
                    let event = ParseEvent(
                        kind: .didFinishBox(header: header, depth: finished.depth),
                        offset: header.endOffset
                    )
                    continuation.yield(event)
                    continue
                } else {
                    continuation.finish()
                    return
                }
            }

            var parent = frame
            let offset = parent.cursor
            let header = try BoxHeaderDecoder.readHeader(
                from: reader,
                at: offset,
                inParentRange: parent.range
            )
            parent.cursor = header.range.upperBound
            stack[stack.count - 1] = parent

            let depth = parent.depth + 1
            continuation.yield(
                ParseEvent(
                    kind: .willStartBox(header: header, depth: depth),
                    offset: header.startOffset
                )
            )

            let payloadRange = header.payloadRange
            let shouldParseChildren = isContainer(header: header) && payloadRange.lowerBound < payloadRange.upperBound
            stack.append(Frame(
                header: header,
                range: payloadRange,
                cursor: payloadRange.lowerBound,
                depth: depth,
                shouldParseChildren: shouldParseChildren
            ))
        }
    }

    private static func isContainer(header: BoxHeader) -> Bool {
        containerTypes.contains(header.type.rawValue)
    }

    private static let containerTypes: Set<String> = [
        "moov", "trak", "mdia", "minf", "dinf", "stbl", "edts", "mvex", "moof", "traf",
        "mfra", "tref", "udta", "strk", "strd", "sinf", "schi", "stsd", "meta", "ilst"
    ]
}
