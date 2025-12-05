import Foundation

extension StructuredPayload {
    struct ValidationMetadataPayload: Encodable {
        let activePresetID: String
        let disabledRules: [String]

        init(metadata: ValidationMetadata) {
            self.activePresetID = metadata.activePresetID
            self.disabledRules = metadata.disabledRuleIDs
        }
    }
}
