import Foundation

public struct StreamingBoxWalker: Sendable {
    public typealias CancellationCheck = () throws -> Void
    public typealias EventHandler = (ParseEvent) -> Void
    public typealias IssueHandler = (ParseIssue) -> Void
    public typealias FinishHandler = () -> Void

    public init() {}

    public func walk(
        reader: RandomAccessReader,
        cancellationCheck: CancellationCheck,
        options: ParsePipeline.Options = .strict,
        onEvent: EventHandler,
        onIssue: IssueHandler = { _ in },
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
            let headerResult = BoxHeaderDecoder.readHeader(
                from: reader,
                at: offset,
                inParentRange: parent.range
            )
            let header: BoxHeader
            switch headerResult {
            case let .success(decodedHeader):
                header = decodedHeader
            case let .failure(error):
                guard !options.abortOnStructuralError else {
                    throw error
                }

                let issue = Self.issue(
                    for: error,
                    parent: parent,
                    attemptedOffset: offset,
                    readerLength: reader.length
                )
                onIssue(issue)
                parent.cursor = parent.range.upperBound
                stack[stack.count - 1] = parent
                continue
            }
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

    static func issue(
        for error: BoxHeaderDecodingError,
        parent: Frame,
        attemptedOffset: Int64,
        readerLength: Int64
    ) -> ParseIssue {
        let affectedNodeIDs: [Int64]
        if let header = parent.header {
            affectedNodeIDs = [header.startOffset]
        } else {
            affectedNodeIDs = []
        }

        let details = issueDetails(
            for: error,
            attemptedOffset: attemptedOffset,
            parentRange: parent.range,
            readerLength: readerLength
        )

        return ParseIssue(
            severity: .error,
            code: details.code,
            message: details.message,
            byteRange: details.byteRange,
            affectedNodeIDs: affectedNodeIDs
        )
    }

    static func issueDetails(
        for error: BoxHeaderDecodingError,
        attemptedOffset: Int64,
        parentRange: Range<Int64>,
        readerLength: Int64
    ) -> (code: String, message: String, byteRange: Range<Int64>?) {
        switch error {
        case let .offsetOutsideParent(offset, parentRange):
            let range = makeRange(
                start: offset,
                end: min(offset + 1, parentRange.upperBound)
            )
            return (
                "header.offset_outside_parent",
                "Header offset \(offset) lies outside parent range \(format(range: parentRange)).",
                range
            )
        case let .offsetBeyondReader(length, offset):
            let range = makeRange(start: offset, end: min(offset + 1, length))
            return (
                "header.offset_beyond_reader",
                "Header offset \(offset) is beyond reader length \(length).",
                range
            )
        case let .truncatedField(expected, actual):
            let end = attemptedOffset + Int64(expected)
            let range = makeRange(
                start: attemptedOffset,
                end: min(end, parentRange.upperBound)
            )
            return (
                "header.truncated_field",
                "Header field truncated (expected \(expected) bytes, read \(actual)).",
                range
            )
        case let .invalidFourCharacterCode(data):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 8, parentRange.upperBound)
            )
            let hex = data.map { String(format: "%02X", $0) }.joined()
            return (
                "header.invalid_fourcc",
                "Encountered invalid four-character code 0x\(hex).",
                range
            )
        case .zeroSizeWithoutParent:
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 8, parentRange.upperBound)
            )
            return (
                "header.zero_size_without_parent",
                "Encountered zero-sized box without parent context to infer length.",
                range
            )
        case let .sizeOutOfRange(size):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 16, parentRange.upperBound)
            )
            return (
                "header.size_out_of_range",
                "Box size \(size) exceeds maximum supported range.",
                range
            )
        case let .invalidSize(totalSize, headerSize):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 16, parentRange.upperBound)
            )
            return (
                "header.invalid_size",
                "Invalid box size: total \(totalSize), header \(headerSize).",
                range
            )
        case let .exceedsParent(expectedEnd, parentEnd):
            let range = makeRange(start: parentEnd, end: expectedEnd)
            return (
                "header.exceeds_parent",
                "Box extends past parent boundary (expected end \(expectedEnd), parent end \(parentEnd)).",
                range
            )
        case let .exceedsReader(expectedEnd, readerLength):
            let range = makeRange(start: readerLength, end: expectedEnd)
            return (
                "header.exceeds_reader",
                "Box extends past reader length (expected end \(expectedEnd), reader length \(readerLength)).",
                range
            )
        case let .readerError(underlying):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 8, parentRange.upperBound)
            )
            return (
                "header.reader_error",
                "Reader error while decoding header: \(underlying.localizedDescription)",
                range
            )
        }
    }

    static func makeRange(start: Int64, end: Int64) -> Range<Int64>? {
        guard end > start else { return nil }
        return start..<end
    }

    static func format(range: Range<Int64>) -> String {
        "\(range.lowerBound)..<\(range.upperBound)"
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
