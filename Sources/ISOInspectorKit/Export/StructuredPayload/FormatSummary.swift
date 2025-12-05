import Foundation

extension StructuredPayload {
    struct FormatSummary: Encodable {
        let majorBrand: String?
        let minorVersion: Int?
        let compatibleBrands: [String]?
        let durationSeconds: Double?
        let byteSize: Int?
        let bitrate: Int?
        let trackCount: Int?

        init?(tree: ParseTree) {
            let scan = FormatSummary.scan(tree: tree)
            let majorBrand = scan.fileType?.majorBrand.rawValue
            let minorVersion = scan.fileType.map { Int($0.minorVersion) }
            let compatibleBrands = scan.fileType?.compatibleBrands.map(\.rawValue)
            let durationSeconds = FormatSummary.durationSeconds(from: scan.movieHeader)
            let byteSize = FormatSummary.byteSize(from: scan.maximumEndOffset)
            let bitrate = FormatSummary.bitrate(
                byteSize: byteSize, durationSeconds: durationSeconds)
            let trackCount = scan.trackCount > 0 ? scan.trackCount : nil

            guard
                majorBrand != nil || minorVersion != nil || !(compatibleBrands?.isEmpty ?? true)
                    || durationSeconds != nil || byteSize != nil || bitrate != nil
                    || trackCount != nil
            else { return nil }

            self.majorBrand = majorBrand
            self.minorVersion = minorVersion
            self.compatibleBrands = compatibleBrands
            self.durationSeconds = durationSeconds
            self.byteSize = byteSize
            self.bitrate = bitrate
            self.trackCount = trackCount
        }

        private static func scan(tree: ParseTree) -> ScanResult {
            var fileTypeBox: ParsedBoxPayload.FileTypeBox?
            var movieHeaderBox: ParsedBoxPayload.MovieHeaderBox?
            var maximumEndOffset: Int64 = 0
            var trackCounter = 0

            for node in flatten(nodes: tree.nodes) {
                if fileTypeBox == nil, let fileType = node.payload?.fileType {
                    fileTypeBox = fileType
                }
                if movieHeaderBox == nil, let movieHeader = node.payload?.movieHeader {
                    movieHeaderBox = movieHeader
                }
                if node.header.type.rawValue == "trak" { trackCounter += 1 }
                maximumEndOffset = max(maximumEndOffset, node.header.endOffset)
            }

            return ScanResult(
                fileType: fileTypeBox, movieHeader: movieHeaderBox,
                maximumEndOffset: maximumEndOffset, trackCount: trackCounter)
        }

        private static func durationSeconds(from movieHeader: ParsedBoxPayload.MovieHeaderBox?)
            -> Double?
        {
            guard let header = movieHeader, header.timescale > 0 else { return nil }
            return Double(header.duration) / Double(header.timescale)
        }

        private static func byteSize(from maximumEndOffset: Int64) -> Int? {
            guard maximumEndOffset > 0 else { return nil }
            return Int(clamping: maximumEndOffset)
        }

        private static func bitrate(byteSize: Int?, durationSeconds: Double?) -> Int? {
            guard let bytes = byteSize, let duration = durationSeconds, duration > 0 else {
                return nil
            }
            return Int((Double(bytes) * 8.0 / duration).rounded())
        }

        private struct ScanResult {
            let fileType: ParsedBoxPayload.FileTypeBox?
            let movieHeader: ParsedBoxPayload.MovieHeaderBox?
            let maximumEndOffset: Int64
            let trackCount: Int
        }

        private static func flatten(nodes: [ParseTreeNode]) -> [ParseTreeNode] {
            var result: [ParseTreeNode] = []
            for node in nodes {
                result.append(node)
                result.append(contentsOf: flatten(nodes: node.children))
            }
            return result
        }

        private enum CodingKeys: String, CodingKey {
            case majorBrand = "major_brand"
            case minorVersion = "minor_version"
            case compatibleBrands = "compatible_brands"
            case durationSeconds = "duration_seconds"
            case byteSize = "byte_size"
            case bitrate
            case trackCount = "track_count"
        }
    }
}
