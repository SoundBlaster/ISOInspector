import SpecificationCore

/// Determines which track-header versions this parser understands.
struct TrackHeaderVersionSpecification: Specification {
    static let supportedVersions: [UInt8] = [0, 1]

    func isSatisfiedBy(_ version: UInt8) -> Bool { Self.supportedVersions.contains(version) }
}
