import Foundation

/// High-level classification buckets for ISO BMFF boxes used by filters and UI affordances.
public enum BoxCategory: String, CaseIterable, Hashable, Sendable {
    case metadata
    case media
    case index
    case container
    case other
}
