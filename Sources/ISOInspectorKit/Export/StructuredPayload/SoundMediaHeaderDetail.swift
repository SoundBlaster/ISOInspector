import Foundation

extension StructuredPayload {
    struct SoundMediaHeaderDetail: Encodable {
        let version: UInt8
        let flags: UInt32
        let balance: Double
        let balanceRaw: Int16
        
        init(box: ParsedBoxPayload.SoundMediaHeaderBox) {
            self.version = box.version
            self.flags = box.flags
            self.balance = box.balance
            self.balanceRaw = box.balanceRaw
        }
        
        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case balance
            case balanceRaw = "balance_raw"
        }
    }
}
