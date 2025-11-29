import Foundation

/// Validates ISO base media file box structures using a collection of validation rules.
///
/// The validator applies all configured rules to each parse event and aggregates
/// validation issues. Rules are organized in the `ValidationRules` directory with
/// each rule focusing on a specific aspect of box structure validation.
///
/// Default rules cover:
/// - Structural integrity (size, boundaries, nesting)
/// - ISO 14496-12 compliance (version/flags, container relationships)
/// - Codec-specific validation (AVC, HEVC configurations)
/// - Timing and sample table correlations
/// - Fragment validation for segmented/streaming files
/// - Ordering and layout best practices
struct BoxValidator: Sendable {
  private let rules: [any BoxValidationRule]

  /// Creates a validator with the specified rules.
  ///
  /// - Parameter rules: Array of validation rules to apply. Defaults to all standard rules.
  init(rules: [any BoxValidationRule] = BoxValidator.defaultRules) {
    self.rules = rules
  }

  /// Applies all validation rules to a parse event and returns an annotated event.
  ///
  /// - Parameters:
  ///   - event: The parse event to validate
  ///   - reader: Random access reader for inspecting box payload data
  /// - Returns: Parse event with validation issues attached (if any were found)
  func annotate(event: ParseEvent, reader: RandomAccessReader) -> ParseEvent {
    let issues = rules.flatMap { $0.issues(for: event, reader: reader) }
    guard !issues.isEmpty else {
      return event
    }
    return ParseEvent(
      kind: event.kind,
      offset: event.offset,
      metadata: event.metadata,
      payload: event.payload,
      validationIssues: issues,
      issues: event.issues
    )
  }
}

extension BoxValidator {
  /// Default set of validation rules covering ISO base media file format compliance.
  fileprivate static var defaultRules: [any BoxValidationRule] {
    [
      StructuralSizeRule(),
      ContainerBoundaryRule(),
      FileTypeOrderingRule(),
      MovieDataOrderingRule(),
      TopLevelOrderingAdvisoryRule(),
      VersionFlagsRule(),
      EditListValidationRule(),
      SampleTableCorrelationRule(),
      CodecConfigurationValidationRule(),
      FragmentSequenceRule(),
      FragmentRunValidationRule(),
      UnknownBoxRule(),
    ]
  }
}
