#if canImport(Combine)
    import Foundation

    struct HexByteAccessibilityFormatter {
        func label(for byte: UInt8, at offset: Int64, highlighted: Bool) -> String {
            let hex = String(format: "0x%02X", byte)
            var components = ["Byte \(hex) at offset \(offset)"]
            if highlighted { components.append("selected") }
            return components.joined(separator: ", ")
        }
    }
#endif
