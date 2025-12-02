import Foundation

struct BatchValidationSummary: Sendable {
    struct File: Sendable {
        let url: URL
        let size: Int64?
        let boxCount: Int
        let errorCount: Int
        let warningCount: Int
        let infoCount: Int
        let status: Status
        let notes: String?
    }

    struct Totals: Sendable {
        var fileCount: Int = 0
        var knownSizeBytes: Int64 = 0
        var unknownSizeCount: Int = 0
        var boxCount: Int = 0
        var errorCount: Int = 0
        var warningCount: Int = 0
        var infoCount: Int = 0
        var validationFailureCount: Int = 0
        var parseFailureCount: Int = 0

        var hasUnknownSizes: Bool { unknownSizeCount > 0 }

        var statusSummary: Status {
            if parseFailureCount > 0 { return .parseFailed }

            if validationFailureCount > 0 { return .validationFailed }

            if warningCount > 0 { return .warnings }

            return .success
        }
    }

    enum Status: String, Sendable {
        case success = "success"
        case warnings = "warnings"
        case validationFailed = "validation-failed"
        case parseFailed = "parse-failed"

        var displayLabel: String {
            switch self {
            case .success: return "Success"
            case .warnings: return "Warnings"
            case .validationFailed: return "Validation Failed"
            case .parseFailed: return "Parse Failed"
            }
        }
    }

    var files: [File]
    var totals: Totals

    var hasWarnings: Bool { files.contains { $0.status == .warnings } }

    var hasValidationFailures: Bool { files.contains { $0.status == .validationFailed } }

    var hasParseFailures: Bool { files.contains { $0.status == .parseFailed } }

    func formattedLines() -> [String] {
        let headers = ["File", "Size", "Boxes", "Errors", "Warnings", "Info", "Status", "Notes"]
        var rows: [[String]] = files.map { file in
            [
                file.url.path, formattedSize(file.size), String(file.boxCount),
                String(file.errorCount), String(file.warningCount), String(file.infoCount),
                file.status.displayLabel, file.notes ?? "",
            ]
        }

        let totalsSize = formattedTotalsSize()
        let totalsNotes = formattedTotalsNotes()
        rows.append([
            "Totals", totalsSize, String(totals.boxCount), String(totals.errorCount),
            String(totals.warningCount), String(totals.infoCount),
            totals.statusSummary.displayLabel, totalsNotes,
        ])

        let columnCount = headers.count
        var widths = Array(repeating: 0, count: columnCount)
        for column in 0..<columnCount {
            var maxWidth = headers[column].count
            for row in rows where column < row.count { maxWidth = max(maxWidth, row[column].count) }
            widths[column] = maxWidth
        }

        var adjustedRows: [[String]] = rows
        for index in adjustedRows.indices {
            adjustedRows[index] = pad(values: adjustedRows[index], widths: widths)
        }

        let paddedHeaders = pad(values: headers, widths: widths)
        var output: [String] = [paddedHeaders.joined(separator: "  ")]
        output.append(contentsOf: adjustedRows.map { $0.joined(separator: "  ") })
        return output
    }

    func csvData() -> Data {
        var rows: [[String]] = [
            ["file", "size_bytes", "boxes", "errors", "warnings", "info", "status", "notes"]
        ]

        rows.append(
            contentsOf: files.map { file in
                [
                    file.url.path, file.size.map(String.init) ?? "", String(file.boxCount),
                    String(file.errorCount), String(file.warningCount), String(file.infoCount),
                    file.status.rawValue, file.notes ?? "",
                ]
            })

        let totalsNotes = formattedTotalsNotes()
        rows.append([
            "TOTALS", String(totals.knownSizeBytes), String(totals.boxCount),
            String(totals.errorCount), String(totals.warningCount), String(totals.infoCount),
            totals.statusSummary.rawValue, totalsNotes,
        ])

        let csv = rows.map { $0.map(Self.escapeCSV).joined(separator: ",") }.joined(separator: "\n")
        return Data(csv.utf8)
    }

    private func formattedSize(_ size: Int64?) -> String {
        guard let size else { return "-" }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }

    private func formattedTotalsSize() -> String {
        if totals.knownSizeBytes == 0 { return totals.hasUnknownSizes ? "*" : "0 B" }

        let formatted = ByteCountFormatter.string(
            fromByteCount: totals.knownSizeBytes, countStyle: .file)
        return totals.hasUnknownSizes ? formatted + "*" : formatted
    }

    private func formattedTotalsNotes() -> String {
        var components: [String] = []
        if totals.parseFailureCount > 0 {
            components.append("parse failures: \(totals.parseFailureCount)")
        }
        if totals.validationFailureCount > 0 {
            components.append("validation failures: \(totals.validationFailureCount)")
        }
        return components.joined(separator: ", ")
    }

    private func pad(values: [String], widths: [Int]) -> [String] {
        values.enumerated().map { index, value in
            let width = widths[index]
            if value.count >= width { return value }
            return value.padding(toLength: width, withPad: " ", startingAt: 0)
        }
    }

    private static func escapeCSV(_ value: String) -> String {
        if value.isEmpty { return value }

        let needsEscaping = value.contains { character in
            character == "," || character == "\"" || character == "\n"
        }

        guard needsEscaping else { return value }

        let escapedQuotes = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"" + escapedQuotes + "\""
    }
}

extension BatchValidationSummary {
    struct Builder {
        private(set) var files: [File] = []
        private(set) var totals = Totals()

        struct Counts {
            let boxes: Int
            let errors: Int
            let warnings: Int
            let info: Int

            static let zero = Counts(boxes: 0, errors: 0, warnings: 0, info: 0)
        }

        struct Metrics {
            let size: Int64?
            let counts: Counts
            let status: Status
            let notes: String?

            init(size: Int64?, counts: Counts, status: Status, notes: String? = nil) {
                self.size = size
                self.counts = counts
                self.status = status
                self.notes = notes
            }
        }

        mutating func append(fileURL: URL, metrics: Metrics) {
            files.append(
                File(
                    url: fileURL, size: metrics.size, boxCount: metrics.counts.boxes,
                    errorCount: metrics.counts.errors, warningCount: metrics.counts.warnings,
                    infoCount: metrics.counts.info, status: metrics.status, notes: metrics.notes))

            totals.fileCount += 1
            if let size = metrics.size {
                totals.knownSizeBytes += size
            } else {
                totals.unknownSizeCount += 1
            }
            totals.boxCount += metrics.counts.boxes
            totals.errorCount += metrics.counts.errors
            totals.warningCount += metrics.counts.warnings
            totals.infoCount += metrics.counts.info

            switch metrics.status {
            case .validationFailed: totals.validationFailureCount += 1
            case .parseFailed: totals.parseFailureCount += 1
            case .success, .warnings: break
            }
        }

        mutating func appendParseFailure(fileURL: URL, size: Int64?, reason: String) {
            append(
                fileURL: fileURL,
                metrics: .init(size: size, counts: .zero, status: .parseFailed, notes: reason))
        }

        func build(sorted: Bool = true) -> BatchValidationSummary {
            let orderedFiles: [File]
            if sorted {
                orderedFiles = files.sorted { lhs, rhs in lhs.url.path < rhs.url.path }
            } else {
                orderedFiles = files
            }
            return BatchValidationSummary(files: orderedFiles, totals: totals)
        }
    }
}
