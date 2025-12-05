import Foundation

extension StructuredPayload {
    struct EditListDetail: Encodable {
        struct Entry: Encodable {
            let index: UInt32
            let segmentDuration: UInt64
            let mediaTime: Int64
            let mediaRateInteger: Int16
            let mediaRateFraction: UInt16
            let mediaRate: Double
            let segmentDurationSeconds: Double?
            let mediaTimeSeconds: Double?
            let presentationStart: UInt64
            let presentationEnd: UInt64
            let presentationStartSeconds: Double?
            let presentationEndSeconds: Double?
            let isEmptyEdit: Bool

            init(entry: ParsedBoxPayload.EditListBox.Entry) {
                self.index = entry.index
                self.segmentDuration = entry.segmentDuration
                self.mediaTime = entry.mediaTime
                self.mediaRateInteger = entry.mediaRateInteger
                self.mediaRateFraction = entry.mediaRateFraction
                self.mediaRate = entry.mediaRate
                self.segmentDurationSeconds = entry.segmentDurationSeconds
                self.mediaTimeSeconds = entry.mediaTimeSeconds
                self.presentationStart = entry.presentationStart
                self.presentationEnd = entry.presentationEnd
                self.presentationStartSeconds = entry.presentationStartSeconds
                self.presentationEndSeconds = entry.presentationEndSeconds
                self.isEmptyEdit = entry.isEmptyEdit
            }

            private enum CodingKeys: String, CodingKey {
                case index
                case segmentDuration = "segment_duration"
                case mediaTime = "media_time"
                case mediaRateInteger = "media_rate_integer"
                case mediaRateFraction = "media_rate_fraction"
                case mediaRate = "media_rate"
                case segmentDurationSeconds = "segment_duration_seconds"
                case mediaTimeSeconds = "media_time_seconds"
                case presentationStart = "presentation_start"
                case presentationEnd = "presentation_end"
                case presentationStartSeconds = "presentation_start_seconds"
                case presentationEndSeconds = "presentation_end_seconds"
                case isEmptyEdit = "is_empty_edit"
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(index, forKey: .index)
                try container.encode(segmentDuration, forKey: .segmentDuration)
                try container.encode(mediaTime, forKey: .mediaTime)
                try container.encode(mediaRateInteger, forKey: .mediaRateInteger)
                try container.encode(mediaRateFraction, forKey: .mediaRateFraction)
                try container.encode(mediaRate, forKey: .mediaRate)

                try encodeSecondsValue(
                    segmentDurationSeconds, forKey: .segmentDurationSeconds, in: &container)
                try encodeSecondsValue(mediaTimeSeconds, forKey: .mediaTimeSeconds, in: &container)

                try container.encode(presentationStart, forKey: .presentationStart)
                try container.encode(presentationEnd, forKey: .presentationEnd)

                try encodeSecondsValue(
                    presentationStartSeconds, forKey: .presentationStartSeconds, in: &container)
                try encodeSecondsValue(
                    presentationEndSeconds, forKey: .presentationEndSeconds, in: &container)

                try container.encode(isEmptyEdit, forKey: .isEmptyEdit)
            }

            private func encodeSecondsValue(
                _ value: Double?, forKey key: CodingKeys,
                in container: inout KeyedEncodingContainer<CodingKeys>
            ) throws {
                guard let value, let decimal = Self.decimal(from: value) else { return }
                try container.encode(decimal, forKey: key)
            }

            private static func decimal(from seconds: Double) -> Decimal? {
                let formatted = BoxParserRegistry.DefaultParsers.formatSeconds(seconds)
                return Decimal(string: formatted, locale: Locale(identifier: "en_US_POSIX"))
            }
        }

        let version: UInt8
        let flags: UInt32
        let entryCount: UInt32
        let movieTimescale: UInt32?
        let mediaTimescale: UInt32?
        let entries: [Entry]

        init(box: ParsedBoxPayload.EditListBox) {
            self.version = box.version
            self.flags = box.flags
            self.entryCount = box.entryCount
            self.movieTimescale = box.movieTimescale
            self.mediaTimescale = box.mediaTimescale
            self.entries = box.entries.map(Entry.init)
        }

        private enum CodingKeys: String, CodingKey {
            case version
            case flags
            case entryCount = "entry_count"
            case movieTimescale = "movie_timescale"
            case mediaTimescale = "media_timescale"
            case entries
        }
    }
}
