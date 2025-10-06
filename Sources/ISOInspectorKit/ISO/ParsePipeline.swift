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
                    let walker = StreamingBoxWalker()
                    do {
                        try walker.walk(
                            reader: reader,
                            cancellationCheck: { try Task.checkCancellation() },
                            onEvent: { event in
                                continuation.yield(event)
                            },
                            onFinish: {
                                continuation.finish()
                            }
                        )
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
}
