import Foundation

public struct StreamingBoxWalker: Sendable {
    public typealias CancellationCheck = () throws -> Void
    public typealias EventHandler = (ParseEvent) -> Void
    public typealias FinishHandler = () -> Void

    public init() {}

    public func walk(
        reader: RandomAccessReader,
        cancellationCheck: CancellationCheck,
        onEvent: EventHandler,
        onFinish: FinishHandler
    ) throws {
        var stack: [Frame] = [Frame(
            header: nil,
            range: Int64(0)..<reader.length,
            cursor: Int64(0),
            depth: -1,
            shouldParseChildren: true
        )]

        while let frame = stack.last {
            try cancellationCheck()

            if !frame.shouldParseChildren || frame.cursor >= frame.range.upperBound {
                let finished = stack.removeLast()
                if let header = finished.header {
                    let event = ParseEvent(
                        kind: .didFinishBox(header: header, depth: finished.depth),
                        offset: header.endOffset
                    )
                    onEvent(event)
                    continue
                } else {
                    onFinish()
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
            let startEvent = ParseEvent(
                kind: .willStartBox(header: header, depth: depth),
                offset: header.startOffset
            )
            onEvent(startEvent)

            let payloadRange = header.payloadRange
            let shouldParseChildren = Self.shouldParseChildren(for: header, payloadRange: payloadRange)
            let initialCursor = Self.initialCursor(for: header, payloadRange: payloadRange)
            stack.append(Frame(
                header: header,
                range: payloadRange,
                cursor: initialCursor,
                depth: depth,
                shouldParseChildren: shouldParseChildren
            ))
        }
    }
}

private extension StreamingBoxWalker {
    struct Frame {
        let header: BoxHeader?
        let range: Range<Int64>
        var cursor: Int64
        let depth: Int
        let shouldParseChildren: Bool
    }

    static func shouldParseChildren(for header: BoxHeader, payloadRange: Range<Int64>) -> Bool {
        guard payloadRange.lowerBound < payloadRange.upperBound else {
            return false
        }
        return FourCharContainerCode.isContainer(header)
    }

    static func initialCursor(for header: BoxHeader, payloadRange: Range<Int64>) -> Int64 {
        guard payloadRange.lowerBound < payloadRange.upperBound else {
            return payloadRange.lowerBound
        }
        if header.type.rawValue == "meta" {
            let available = payloadRange.upperBound - payloadRange.lowerBound
            let skip = min(Int64(8), available)
            return payloadRange.lowerBound + skip
        }
        return payloadRange.lowerBound
    }
}
