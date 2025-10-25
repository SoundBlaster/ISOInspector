#if canImport(Combine)
import Foundation
import ISOInspectorKit

struct AccessibilityDescriptor: Equatable {
    let label: String
    let value: String?
    let hint: String?
}

extension AccessibilityDescriptor {
    static func outlineRow(
        _ row: ParseTreeOutlineRow,
        isBookmarked: Bool
    ) -> AccessibilityDescriptor {
        var components: [String] = []

        if let displayName = row.node.metadata?.name, !displayName.isEmpty {
            components.append(displayName)
        } else {
            components.append(row.displayName)
        }

        components.append(row.typeDescription)

        if let summary = row.summary, !summary.isEmpty {
            components.append(summary)
        }

        if let corruption = row.corruptionSummary {
            components.append(corruption.accessibilityLabel)
        } else if let severity = row.dominantSeverity {
            components.append(severity.accessibilityDescription)
        } else if row.hasValidationIssues {
            components.append("Additional validation notes available")
        }

        let childCount = row.node.children.count
        if childCount > 0 {
            let label = childCount == 1 ? "1 child" : "\(childCount) children"
            components.append(label)
        }

        if row.isSearchMatch {
            components.append("Matches current search")
        } else if row.hasMatchingDescendant {
            components.append("Contains matching descendant")
        }

        let label = components.joined(separator: ". ")
        let value = isBookmarked ? "Bookmarked" : nil
        let hint = "Press Return to expand or collapse. Press Space to toggle bookmark."

        return AccessibilityDescriptor(label: label, value: value, hint: hint)
    }
}

extension ParseTreeOutlineRow {
    func accessibilityDescriptor(isBookmarked: Bool) -> AccessibilityDescriptor {
        AccessibilityDescriptor.outlineRow(self, isBookmarked: isBookmarked)
    }
}

extension ParseTreeNodeDetail {
    var accessibilitySummary: String {
        var components: [String] = []
        components.append(header.type.description)
        if let name = metadata?.name, !name.isEmpty {
            components.append(name)
        }
        if let summary = metadata?.summary, !summary.isEmpty {
            components.append(summary)
        }
        components.append("Status \(status.rawValue.capitalized)")

        let rangeDescription = "Range \(header.range.lowerBound) – \(header.range.upperBound)"
        let payloadDescription = "Payload \(header.payloadRange.lowerBound) – \(header.payloadRange.upperBound)"
        components.append(rangeDescription)
        components.append(payloadDescription)

        if let version = metadata?.version {
            components.append("Version \(version)")
        }
        if let flags = metadata?.flags {
            components.append("Flags 0x\(String(flags, radix: 16, uppercase: true))")
        }

        func rangeString(_ range: Range<Int64>) -> String {
            "\(range.lowerBound) – \(range.upperBound)"
        }

        if let payload {
            if let encryption = payload.sampleEncryption {
                var encryptionParts: [String] = ["Sample encryption entries \(encryption.sampleCount)"]
                if encryption.overrideTrackEncryptionDefaults {
                    encryptionParts.append("Overrides defaults")
                }
                if encryption.usesSubsampleEncryption {
                    encryptionParts.append("Includes subsample encryption")
                }
                if let ivSize = encryption.perSampleIVSize {
                    encryptionParts.append("Per-sample IV size \(ivSize)")
                }
                if let algorithm = encryption.algorithmIdentifier {
                    encryptionParts.append(String(format: "Algorithm 0x%06X", algorithm))
                }
                if let keyRange = encryption.keyIdentifierRange {
                    encryptionParts.append("Key identifier range \(rangeString(keyRange))")
                }
                if let sampleBytes = encryption.sampleInfoByteLength {
                    encryptionParts.append("Sample info bytes \(sampleBytes)")
                }
                if let sampleRange = encryption.sampleInfoRange {
                    encryptionParts.append("Sample info range \(rangeString(sampleRange))")
                }
                if let constantBytes = encryption.constantIVByteLength {
                    encryptionParts.append("Constant IV bytes \(constantBytes)")
                }
                if let constantRange = encryption.constantIVRange {
                    encryptionParts.append("Constant IV range \(rangeString(constantRange))")
                }
                components.append(encryptionParts.joined(separator: ". "))
            }
            if let offsets = payload.sampleAuxInfoOffsets {
                var offsetParts: [String] = ["Auxiliary info offsets entries \(offsets.entryCount)"]
                offsetParts.append("Bytes per entry \(offsets.entrySizeBytes)")
                if let type = offsets.auxInfoType?.rawValue, !type.isEmpty {
                    offsetParts.append("Type \(type)")
                }
                if let parameter = offsets.auxInfoTypeParameter {
                    offsetParts.append("Parameter \(parameter)")
                }
                if let byteLength = offsets.entriesByteLength {
                    offsetParts.append("Entries bytes \(byteLength)")
                }
                if let entriesRange = offsets.entriesRange {
                    offsetParts.append("Range \(rangeString(entriesRange))")
                }
                components.append(offsetParts.joined(separator: ". "))
            }
            if let sizes = payload.sampleAuxInfoSizes {
                var sizeParts: [String] = [
                    "Auxiliary info sizes default \(sizes.defaultSampleInfoSize)",
                    "Entry count \(sizes.entryCount)"
                ]
                if let type = sizes.auxInfoType?.rawValue, !type.isEmpty {
                    sizeParts.append("Type \(type)")
                }
                if let parameter = sizes.auxInfoTypeParameter {
                    sizeParts.append("Parameter \(parameter)")
                }
                if let variableBytes = sizes.variableEntriesByteLength {
                    sizeParts.append("Variable bytes \(variableBytes)")
                }
                if let variableRange = sizes.variableEntriesRange {
                    sizeParts.append("Variable range \(rangeString(variableRange))")
                }
                components.append(sizeParts.joined(separator: ". "))
            }
        }

        if validationIssues.isEmpty {
            components.append("No validation issues")
        } else {
            let issueSummaries = validationIssues.map { issue in
                "\(issue.severity.accessibilityDescription): \(issue.message)"
            }
            components.append(issueSummaries.joined(separator: ". "))
        }

        return components.joined(separator: ". ")
    }
}

extension ValidationIssue.Severity {
    var accessibilityDescription: String {
        switch self {
        case .info:
            return "informational issue"
        case .warning:
            return "warning issue"
        case .error:
            return "error issue"
        }
    }
}
#endif
