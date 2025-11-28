import Foundation

/// Validates container box boundary integrity.
///
/// Maintains a stack to track container hierarchy and validates:
/// - Child boxes start at expected offsets
/// - Child boxes don't overlap
/// - Child boxes don't extend beyond parent boundaries
/// - Container state is properly balanced (start/finish events match)
///
/// Rule ID: VR-002
final class ContainerBoundaryRule: BoxValidationRule, @unchecked Sendable {
  private struct State {
    let header: BoxHeader
    var nextChildOffset: Int64
    var hasChildren: Bool
  }

  private var stack: [State] = []

  func issues(for event: ParseEvent, reader: RandomAccessReader) -> [ValidationIssue] {
    var issues: [ValidationIssue] = []

    switch event.kind {
    case .willStartBox(let header, let depth):
      if stack.count > depth {
        stack.removeLast(stack.count - depth)
      }
      if stack.count < depth {
        let message =
          "Start event for \(header.identifierString) arrived at depth \(depth) without a matching parent context."
        issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
        stack.removeAll()
      }

      if let parentIndex = stack.indices.last {
        var parent = stack[parentIndex]
        let expectedStart = parent.nextChildOffset
        if header.startOffset < expectedStart {
          let message =
            "Child \(header.identifierString) overlaps previous child inside \(parent.header.identifierString): starts at offset \(header.startOffset) before expected next child at \(expectedStart)."
          issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
        } else if header.startOffset > expectedStart {
          let message =
            "Container \(parent.header.identifierString) expected child to start at offset \(expectedStart) but found \(header.startOffset)."
          issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
        }

        let parentPayloadEnd = parent.header.payloadRange.upperBound
        if header.endOffset > parentPayloadEnd {
          let message =
            "Child \(header.identifierString) extends beyond parent \(parent.header.identifierString) payload (child end \(header.endOffset), parent end \(parentPayloadEnd))."
          issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
        }

        parent.nextChildOffset = max(parent.nextChildOffset, header.endOffset)
        parent.hasChildren = true
        stack[parentIndex] = parent
      }

      let childState = State(
        header: header,
        nextChildOffset: header.payloadRange.lowerBound,
        hasChildren: false
      )
      stack.append(childState)

    case .didFinishBox(let header, let depth):
      if stack.count > depth + 1 {
        stack.removeLast(stack.count - (depth + 1))
      }
      guard stack.count >= depth + 1 else {
        let message =
          "Finish event for \(header.identifierString) arrived at depth \(depth) without an opening start event."
        issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
        stack.removeAll()
        return issues
      }

      let state = stack.removeLast()
      if state.header != header {
        let message =
          "Container stack mismatch: expected to finish \(state.header.identifierString) but received \(header.identifierString)."
        issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
      }

      if state.hasChildren {
        let expectedEnd = state.header.payloadRange.upperBound
        if state.nextChildOffset != expectedEnd {
          let message =
            "Container \(state.header.identifierString) expected to close at offset \(expectedEnd) but consumed \(state.nextChildOffset)."
          issues.append(ValidationIssue(ruleID: "VR-002", message: message, severity: .error))
        }
      }

      if let parentIndex = stack.indices.last {
        var parent = stack[parentIndex]
        parent.nextChildOffset = max(parent.nextChildOffset, header.endOffset)
        parent.hasChildren = true
        stack[parentIndex] = parent
      }
    }

    return issues
  }
}
