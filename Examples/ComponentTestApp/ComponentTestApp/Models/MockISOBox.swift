/// MockISOBox - Sample data model for ISO/MP4 box structure
///
/// Represents a single ISO base media file box (atom) with metadata.
/// Used for demonstration and testing of FoundationUI patterns,
/// particularly BoxTreePattern and InspectorPattern.
///
/// ISO box types reference:
/// - ftyp: File Type Box (brand identification)
/// - moov: Movie Box (container for metadata)
/// - mdat: Media Data Box (actual media samples)
/// - trak: Track Box (individual track)
/// - mdia: Media Box (track media information)
/// - minf: Media Information Box
/// - stbl: Sample Table Box
///
/// Example hierarchy:
/// ```
/// ftyp
/// moov
///   ├─ mvhd
///   └─ trak
///      ├─ tkhd
///      └─ mdia
///         ├─ mdhd
///         ├─ hdlr
///         └─ minf
///            ├─ vmhd
///            ├─ dinf
///            └─ stbl
/// mdat
/// ```

import Foundation
import FoundationUI

/// Mock ISO box structure for demo purposes
struct MockISOBox: Identifiable, Hashable {
    /// Unique identifier
    let id: UUID

    /// Four-character code identifying the box type (e.g., "ftyp", "moov", "mdat")
    let boxType: String

    /// Box size in bytes (includes header + payload)
    let size: Int

    /// Byte offset from start of file
    let offset: Int

    /// Child boxes (nested structure)
    let children: [MockISOBox]

    /// Additional metadata key-value pairs
    let metadata: [String: String]

    /// Status indicator for badge display
    let status: BoxStatus

    /// Box status for visual indicators
    enum BoxStatus {
        case normal
        case warning
        case error
        case highlighted

        var badgeLevel: BadgeLevel {
            switch self {
            case .normal: return .info
            case .warning: return .warning
            case .error: return .error
            case .highlighted: return .success
            }
        }
    }

    // MARK: - Convenience Initializers

    /// Create a mock ISO box with default values
    init(
        id: UUID = UUID(),
        boxType: String,
        size: Int,
        offset: Int,
        children: [MockISOBox] = [],
        metadata: [String: String] = [:],
        status: BoxStatus = .normal
    ) {
        self.id = id
        self.boxType = boxType
        self.size = size
        self.offset = offset
        self.children = children
        self.metadata = metadata
        self.status = status
    }

    // MARK: - Computed Properties

    /// Human-readable description of box type
    var typeDescription: String {
        switch boxType {
        case "ftyp": return "File Type Box"
        case "moov": return "Movie Box"
        case "mdat": return "Media Data Box"
        case "mvhd": return "Movie Header Box"
        case "trak": return "Track Box"
        case "tkhd": return "Track Header Box"
        case "mdia": return "Media Box"
        case "mdhd": return "Media Header Box"
        case "hdlr": return "Handler Reference Box"
        case "minf": return "Media Information Box"
        case "vmhd": return "Video Media Header Box"
        case "smhd": return "Sound Media Header Box"
        case "dinf": return "Data Information Box"
        case "stbl": return "Sample Table Box"
        case "stsd": return "Sample Description Box"
        case "stts": return "Time-to-Sample Box"
        case "stsc": return "Sample-to-Chunk Box"
        case "stsz": return "Sample Size Box"
        case "stco": return "Chunk Offset Box"
        default: return "Unknown Box"
        }
    }

    /// Total size including all children (recursive)
    var totalSize: Int {
        size + children.reduce(0) { $0 + $1.totalSize }
    }

    /// Number of direct children
    var childCount: Int {
        children.count
    }

    /// Total number of descendants (recursive)
    var descendantCount: Int {
        children.count + children.reduce(0) { $0 + $1.descendantCount }
    }

    /// Formatted hex offset
    var hexOffset: String {
        String(format: "0x%08X", offset)
    }

    /// Formatted hex size
    var hexSize: String {
        String(format: "0x%08X", size)
    }

    /// Formatted byte size with units
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

// MARK: - Sample Data Generation

extension MockISOBox {
    /// Generate a realistic ISO/MP4 file structure
    static func sampleISOHierarchy() -> [MockISOBox] {
        [
            // File Type Box
            MockISOBox(
                boxType: "ftyp",
                size: 32,
                offset: 0,
                metadata: [
                    "Major Brand": "isom",
                    "Minor Version": "512",
                    "Compatible Brands": "isomiso2mp41"
                ],
                status: .highlighted
            ),

            // Movie Box (container)
            MockISOBox(
                boxType: "moov",
                size: 4096,
                offset: 32,
                children: [
                    // Movie Header
                    MockISOBox(
                        boxType: "mvhd",
                        size: 108,
                        offset: 40,
                        metadata: [
                            "Version": "0",
                            "Creation Time": "2024-01-15 10:30:00",
                            "Modification Time": "2024-01-15 10:30:00",
                            "Time Scale": "1000",
                            "Duration": "60000"
                        ]
                    ),

                    // Video Track
                    MockISOBox(
                        boxType: "trak",
                        size: 1824,
                        offset: 148,
                        children: [
                            // Track Header
                            MockISOBox(
                                boxType: "tkhd",
                                size: 92,
                                offset: 156,
                                metadata: [
                                    "Version": "0",
                                    "Flags": "0x00000f",
                                    "Track ID": "1",
                                    "Duration": "60000",
                                    "Width": "1920.0",
                                    "Height": "1080.0"
                                ]
                            ),

                            // Media Box
                            MockISOBox(
                                boxType: "mdia",
                                size: 1724,
                                offset: 248,
                                children: [
                                    // Media Header
                                    MockISOBox(
                                        boxType: "mdhd",
                                        size: 32,
                                        offset: 256,
                                        metadata: [
                                            "Version": "0",
                                            "Creation Time": "2024-01-15 10:30:00",
                                            "Time Scale": "30000",
                                            "Duration": "1800000"
                                        ]
                                    ),

                                    // Handler Reference
                                    MockISOBox(
                                        boxType: "hdlr",
                                        size: 45,
                                        offset: 288,
                                        metadata: [
                                            "Handler Type": "vide",
                                            "Handler Name": "VideoHandler"
                                        ]
                                    ),

                                    // Media Information
                                    MockISOBox(
                                        boxType: "minf",
                                        size: 1639,
                                        offset: 333,
                                        children: [
                                            // Video Media Header
                                            MockISOBox(
                                                boxType: "vmhd",
                                                size: 20,
                                                offset: 341,
                                                metadata: [
                                                    "Version": "0",
                                                    "Flags": "0x000001",
                                                    "Graphics Mode": "0",
                                                    "OpColor": "0, 0, 0"
                                                ]
                                            ),

                                            // Data Information
                                            MockISOBox(
                                                boxType: "dinf",
                                                size: 36,
                                                offset: 361,
                                                metadata: [
                                                    "Data Reference": "url "
                                                ]
                                            ),

                                            // Sample Table
                                            MockISOBox(
                                                boxType: "stbl",
                                                size: 1575,
                                                offset: 397,
                                                children: [
                                                    MockISOBox(
                                                        boxType: "stsd",
                                                        size: 150,
                                                        offset: 405,
                                                        metadata: [
                                                            "Entry Count": "1",
                                                            "Format": "avc1"
                                                        ]
                                                    ),
                                                    MockISOBox(
                                                        boxType: "stts",
                                                        size: 24,
                                                        offset: 555,
                                                        metadata: [
                                                            "Entry Count": "1",
                                                            "Sample Count": "1800",
                                                            "Sample Delta": "1000"
                                                        ]
                                                    ),
                                                    MockISOBox(
                                                        boxType: "stsc",
                                                        size: 28,
                                                        offset: 579,
                                                        metadata: [
                                                            "Entry Count": "1",
                                                            "First Chunk": "1",
                                                            "Samples Per Chunk": "1"
                                                        ]
                                                    ),
                                                    MockISOBox(
                                                        boxType: "stsz",
                                                        size: 7220,
                                                        offset: 607,
                                                        metadata: [
                                                            "Sample Count": "1800",
                                                            "Default Size": "0"
                                                        ]
                                                    ),
                                                    MockISOBox(
                                                        boxType: "stco",
                                                        size: 7216,
                                                        offset: 7827,
                                                        metadata: [
                                                            "Entry Count": "1800"
                                                        ]
                                                    )
                                                ]
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
                    ),

                    // Audio Track
                    MockISOBox(
                        boxType: "trak",
                        size: 1624,
                        offset: 1972,
                        children: [
                            MockISOBox(
                                boxType: "tkhd",
                                size: 92,
                                offset: 1980,
                                metadata: [
                                    "Track ID": "2",
                                    "Duration": "60000",
                                    "Volume": "1.0"
                                ]
                            ),
                            MockISOBox(
                                boxType: "mdia",
                                size: 1524,
                                offset: 2072,
                                children: [
                                    MockISOBox(
                                        boxType: "mdhd",
                                        size: 32,
                                        offset: 2080,
                                        metadata: [
                                            "Time Scale": "48000",
                                            "Duration": "2880000"
                                        ]
                                    ),
                                    MockISOBox(
                                        boxType: "hdlr",
                                        size: 45,
                                        offset: 2112,
                                        metadata: [
                                            "Handler Type": "soun",
                                            "Handler Name": "SoundHandler"
                                        ]
                                    ),
                                    MockISOBox(
                                        boxType: "minf",
                                        size: 1439,
                                        offset: 2157,
                                        children: [
                                            MockISOBox(
                                                boxType: "smhd",
                                                size: 16,
                                                offset: 2165,
                                                metadata: [
                                                    "Balance": "0"
                                                ]
                                            )
                                        ]
                                    )
                                ]
                            )
                        ]
                    )
                ],
                status: .normal
            ),

            // Media Data Box
            MockISOBox(
                boxType: "mdat",
                size: 10485760,
                offset: 4128,
                metadata: [
                    "Data Type": "Compressed video and audio samples",
                    "Sample Count": "1800"
                ],
                status: .normal
            )
        ]
    }

    /// Generate a large dataset for performance testing (1000+ boxes)
    static func largeDataset() -> [MockISOBox] {
        var boxes: [MockISOBox] = []
        var currentOffset = 0

        // Generate 50 tracks with nested structure
        for trackIndex in 0..<50 {
            let trackChildren = (0..<20).map { childIndex -> MockISOBox in
                let size = 100
                let offset = currentOffset + 8 + (childIndex * size)
                return MockISOBox(
                    boxType: "stbl",
                    size: size,
                    offset: offset,
                    metadata: [
                        "Track": "\(trackIndex)",
                        "Index": "\(childIndex)"
                    ]
                )
            }

            let trackSize = 8 + (trackChildren.count * 100)
            let track = MockISOBox(
                boxType: "trak",
                size: trackSize,
                offset: currentOffset,
                children: trackChildren,
                metadata: [
                    "Track ID": "\(trackIndex + 1)"
                ]
            )

            boxes.append(track)
            currentOffset += trackSize
        }

        return boxes
    }
}
