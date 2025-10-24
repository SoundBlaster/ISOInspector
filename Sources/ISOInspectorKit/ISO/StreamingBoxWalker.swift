import Foundation

public struct StreamingBoxWalker: Sendable {
    public typealias CancellationCheck = () throws -> Void
    public typealias EventHandler = (ParseEvent) -> Void
    public typealias IssueHandler = (ParseIssue, Int) -> Void
    public typealias FinishHandler = () -> Void

    public init() {}

    public func walk(
        reader: RandomAccessReader,
        cancellationCheck: CancellationCheck,
        options: ParsePipeline.Options = .strict,
        onEvent: EventHandler,
        onIssue: IssueHandler = { _, _ in },
        onFinish: FinishHandler
    ) throws {
        var stack: [Frame] = [Frame(
            header: nil,
            range: Int64(0)..<reader.length,
            cursor: Int64(0),
            depth: -1,
            shouldParseChildren: true
        )]

        func emitIssue(_ issue: ParseIssue, targeting index: Int?, depth: Int) {
            onIssue(issue, depth)
            guard let index else { return }

            stack[index].issueCount += 1
            guard stack[index].issueCount >= options.maxIssuesPerFrame,
                  !stack[index].hasEmittedBudgetIssue else {
                return
            }

            stack[index].hasEmittedBudgetIssue = true
            if let budgetIssue = Self.guardIssueBudget(for: stack[index]) {
                onIssue(budgetIssue, depth)
            }
            stack[index].cursor = stack[index].range.upperBound
            stack[index].furthestCursor = max(stack[index].furthestCursor, stack[index].cursor)
        }

        while let index = stack.indices.last {
            try cancellationCheck()

            var frame = stack[index]

            if !frame.shouldParseChildren || frame.cursor >= frame.range.upperBound {
                stack.removeLast()
                if let header = frame.header {
                    let event = ParseEvent(
                        kind: .didFinishBox(header: header, depth: frame.depth),
                        offset: header.endOffset
                    )
                    onEvent(event)
                    continue
                } else {
                    onFinish()
                    return
                }
            }

            if frame.cursor < frame.furthestCursor {
                let issue = Self.guardCursorRegressionIssue(
                    for: frame,
                    attemptedOffset: frame.cursor
                )
                emitIssue(issue, targeting: frame.header == nil ? nil : index, depth: frame.depth)
                var updatedFrame = stack[index]
                updatedFrame.cursor = updatedFrame.range.upperBound
                updatedFrame.furthestCursor = max(updatedFrame.furthestCursor, updatedFrame.cursor)
                stack[index] = updatedFrame
                continue
            }

            let offset = frame.cursor
            frame.furthestCursor = max(frame.furthestCursor, frame.cursor)

            let headerResult = BoxHeaderDecoder.readHeader(
                from: reader,
                at: offset,
                inParentRange: frame.range
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
                    parent: frame,
                    attemptedOffset: offset,
                    readerLength: reader.length
                )
                emitIssue(issue, targeting: frame.header == nil ? nil : index, depth: frame.depth)
                var updatedFrame = stack[index]
                updatedFrame.cursor = updatedFrame.range.upperBound
                updatedFrame.furthestCursor = max(updatedFrame.furthestCursor, updatedFrame.cursor)
                stack[index] = updatedFrame
                continue
            }

            let remaining = frame.range.upperBound - offset
            let minimumAdvance = max(Int64(1), min(Int64(4), remaining))
            let progress = header.range.upperBound - offset
            if progress < minimumAdvance {
                frame.stalledIterations += 1
                let advancedCursor = min(frame.range.upperBound, offset + minimumAdvance)
                frame.cursor = advancedCursor
                frame.furthestCursor = max(frame.furthestCursor, frame.cursor)
                if frame.stalledIterations >= options.maxStalledIterationsPerFrame {
                    let issue = Self.guardNoProgressIssue(
                        parent: frame,
                        attemptedOffset: offset,
                        advancedTo: advancedCursor
                    )
                    emitIssue(issue, targeting: frame.header == nil ? nil : index, depth: frame.depth)
                    var updatedFrame = stack[index]
                    updatedFrame.cursor = updatedFrame.range.upperBound
                    updatedFrame.furthestCursor = max(updatedFrame.furthestCursor, updatedFrame.cursor)
                    stack[index] = updatedFrame
                } else {
                    stack[index] = frame
                }
                continue
            }

            frame.cursor = header.range.upperBound
            frame.furthestCursor = max(frame.furthestCursor, frame.cursor)
            frame.stalledIterations = 0

            let depth = frame.depth + 1
            let payloadRange = header.payloadRange
            let shouldParseChildren = Self.shouldParseChildren(for: header, payloadRange: payloadRange)
            let initialCursor = Self.initialCursor(for: header, payloadRange: payloadRange)

            if !shouldParseChildren && header.range.count == header.headerSize {
                frame.zeroLengthBoxes += 1
                if frame.zeroLengthBoxes > options.maxZeroLengthBoxesPerParent {
                    if !frame.hasEmittedZeroLengthGuard {
                        frame.hasEmittedZeroLengthGuard = true
                        stack[index] = frame
                        let issue = Self.guardZeroLengthIssue(parent: frame, header: header)
                        emitIssue(issue, targeting: frame.header == nil ? nil : index, depth: frame.depth)
                    } else {
                        stack[index] = frame
                    }
                    continue
                }
            }

            stack[index] = frame

            if depth >= options.maxTraversalDepth {
                let issue = Self.guardRecursionDepthIssue(
                    stack: stack,
                    currentIndex: index,
                    frame: frame,
                    childHeader: header
                )
                emitIssue(issue, targeting: frame.header == nil ? nil : index, depth: frame.depth)
                stack[index].cursor = stack[index].range.upperBound
                stack[index].furthestCursor = max(stack[index].furthestCursor, stack[index].cursor)
                continue
            }

            let startEvent = ParseEvent(
                kind: .willStartBox(header: header, depth: depth),
                offset: header.startOffset
            )
            onEvent(startEvent)

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
    struct IssueDetails {
        let code: String
        let message: String
        let byteRange: Range<Int64>?
    }

    struct Frame {
        let header: BoxHeader?
        let range: Range<Int64>
        var cursor: Int64
        let depth: Int
        let shouldParseChildren: Bool
        var stalledIterations: Int
        var zeroLengthBoxes: Int
        var issueCount: Int
        var hasEmittedBudgetIssue: Bool
        var hasEmittedZeroLengthGuard: Bool
        var furthestCursor: Int64

        init(header: BoxHeader?, range: Range<Int64>, cursor: Int64, depth: Int, shouldParseChildren: Bool) {
            self.header = header
            self.range = range
            self.cursor = cursor
            self.depth = depth
            self.shouldParseChildren = shouldParseChildren
            self.stalledIterations = 0
            self.zeroLengthBoxes = 0
            self.issueCount = 0
            self.hasEmittedBudgetIssue = false
            self.hasEmittedZeroLengthGuard = false
            self.furthestCursor = cursor
        }
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
    ) -> IssueDetails {
        switch error {
        case let .offsetOutsideParent(offset, parentRange):
            let range = makeRange(
                start: offset,
                end: min(offset + 1, parentRange.upperBound)
            )
            return IssueDetails(
                code: "header.offset_outside_parent",
                message: "Header offset \(offset) lies outside parent range \(format(range: parentRange)).",
                byteRange: range
            )
        case let .offsetBeyondReader(length, offset):
            let range = makeRange(start: offset, end: min(offset + 1, length))
            return IssueDetails(
                code: "header.offset_beyond_reader",
                message: "Header offset \(offset) is beyond reader length \(length).",
                byteRange: range
            )
        case let .truncatedField(expected, actual):
            let end = attemptedOffset + Int64(expected)
            let range = makeRange(
                start: attemptedOffset,
                end: min(end, parentRange.upperBound)
            )
            return IssueDetails(
                code: "header.truncated_field",
                message: "Header field truncated (expected \(expected) bytes, read \(actual)).",
                byteRange: range
            )
        case let .invalidFourCharacterCode(data):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 8, parentRange.upperBound)
            )
            let hex = data.map { String(format: "%02X", $0) }.joined()
            return IssueDetails(
                code: "header.invalid_fourcc",
                message: "Encountered invalid four-character code 0x\(hex).",
                byteRange: range
            )
        case .zeroSizeWithoutParent:
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 8, parentRange.upperBound)
            )
            return IssueDetails(
                code: "header.zero_size_without_parent",
                message: "Encountered zero-sized box without parent context to infer length.",
                byteRange: range
            )
        case let .sizeOutOfRange(size):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 16, parentRange.upperBound)
            )
            return IssueDetails(
                code: "header.size_out_of_range",
                message: "Box size \(size) exceeds maximum supported range.",
                byteRange: range
            )
        case let .invalidSize(totalSize, headerSize):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 16, parentRange.upperBound)
            )
            return IssueDetails(
                code: "header.invalid_size",
                message: "Invalid box size: total \(totalSize), header \(headerSize).",
                byteRange: range
            )
        case let .exceedsParent(expectedEnd, parentEnd):
            let range = makeRange(
                start: attemptedOffset,
                end: min(expectedEnd, parentRange.upperBound)
            )
            return IssueDetails(
                code: "payload.truncated",
                message: "Box payload truncated by parent boundary (expected end \(expectedEnd), parent end \(parentEnd)).",
                byteRange: range
            )
        case let .exceedsReader(expectedEnd, readerLength):
            let range = makeRange(
                start: attemptedOffset,
                end: min(expectedEnd, min(readerLength, parentRange.upperBound))
            )
            return IssueDetails(
                code: "payload.truncated",
                message: "Box payload truncated by reader length (expected end \(expectedEnd), reader length \(readerLength)).",
                byteRange: range
            )
        case let .readerError(underlying):
            let range = makeRange(
                start: attemptedOffset,
                end: min(attemptedOffset + 8, parentRange.upperBound)
            )
            return IssueDetails(
                code: "header.reader_error",
                message: "Reader error while decoding header: \(underlying.localizedDescription)",
                byteRange: range
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

    static func guardNoProgressIssue(parent: Frame, attemptedOffset: Int64, advancedTo: Int64) -> ParseIssue {
        let range = makeRange(
            start: attemptedOffset,
            end: min(advancedTo, parent.range.upperBound)
        )
        let message = "Traversal stalled at offset \(hex(attemptedOffset)); advancing to \(hex(advancedTo))."
        let affected = parent.header.map { [$0.startOffset] } ?? []
        return ParseIssue(
            severity: .error,
            code: "guard.no_progress",
            message: message,
            byteRange: range,
            affectedNodeIDs: affected
        )
    }

    static func guardZeroLengthIssue(parent: Frame, header: BoxHeader) -> ParseIssue {
        let message = "Zero-length box at offset \(hex(header.startOffset)) exceeded per-parent budget; skipping payload."
        let affected = parent.header.map { [$0.startOffset] } ?? []
        return ParseIssue(
            severity: .warning,
            code: "guard.zero_size_loop",
            message: message,
            byteRange: header.range,
            affectedNodeIDs: affected
        )
    }

    static func guardRecursionDepthIssue(
        stack: [Frame],
        currentIndex: Int,
        frame: Frame,
        childHeader: BoxHeader
    ) -> ParseIssue {
        let message = "Traversal depth exceeded while decoding \(childHeader.type.rawValue) at \(hex(childHeader.startOffset)); closing parent scope."
        let affected = stack.prefix(currentIndex + 1).compactMap { $0.header?.startOffset }
        return ParseIssue(
            severity: .error,
            code: "guard.recursion_depth_exceeded",
            message: message,
            byteRange: frame.range,
            affectedNodeIDs: affected
        )
    }

    static func guardCursorRegressionIssue(for frame: Frame, attemptedOffset: Int64) -> ParseIssue {
        let message = "Child header at \(hex(attemptedOffset)) regressed before cursor \(hex(frame.furthestCursor)); skipping remaining bytes."
        let range = makeRange(
            start: attemptedOffset,
            end: min(attemptedOffset + 4, frame.range.upperBound)
        )
        let affected = frame.header.map { [$0.startOffset] } ?? []
        return ParseIssue(
            severity: .error,
            code: "guard.cursor_regression",
            message: message,
            byteRange: range,
            affectedNodeIDs: affected
        )
    }

    static func guardIssueBudget(for frame: Frame) -> ParseIssue? {
        guard let header = frame.header else { return nil }
        let range = makeRange(
            start: frame.cursor,
            end: frame.range.upperBound
        )
        let message = "Issue budget exceeded for node at \(hex(header.startOffset)); marking payload partial and skipping remaining bytes."
        return ParseIssue(
            severity: .warning,
            code: "guard.issue_budget_exceeded",
            message: message,
            byteRange: range,
            affectedNodeIDs: [header.startOffset]
        )
    }

    static func hex(_ value: Int64) -> String {
        String(format: "0x%llX", value)
    }
}
