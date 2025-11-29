import Foundation

extension StructuredPayload {
    struct VideoMediaHeaderDetail: Encodable {
        struct Opcolor: Encodable {
            struct Component: Encodable {
                let raw: UInt16
                let normalized: Double
            }

            let red: Component
            let green: Component
            let blue: Component
        }

        let version: UInt8
        let flags: UInt32
        let graphicsMode: UInt16
        let graphicsModeDescription: String?
        let opcolor: Opcolor

        init(box: ParsedBoxPayload.VideoMediaHeaderBox) {
            self.version = box.version
            self.flags = box.flags
            self.graphicsMode = box.graphicsMode
            self.graphicsModeDescription = box.graphicsModeDescription
            self.opcolor = Opcolor(
                red: .init(raw: box.opcolor.red.raw, normalized: box.opcolor.red.normalized),
                green: .init(raw: box.opcolor.green.raw, normalized: box.opcolor.green.normalized),
                blue: .init(raw: box.opcolor.blue.raw, normalized: box.opcolor.blue.normalized)
            )
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case graphicsMode = "graphics_mode"
            case graphicsModeDescription = "graphics_mode_description"
            case opcolor
        }
    }
}
