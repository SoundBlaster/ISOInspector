import Foundation

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

public enum MP4RARegistryEndpoints {
    public static let boxes = URL(string: "https://mp4ra.org/api/boxes")!
}

public protocol MP4RARegistryDataProvider {
    var sourceURL: URL { get }
    func fetchRegistryPayload() throws -> Data
}

private final class MP4RAFetchResultBox: @unchecked Sendable {
    var value: Result<(Data, URLResponse), Swift.Error>?
}

public struct HTTPMP4RARegistryDataProvider: MP4RARegistryDataProvider {
    public enum Error: Swift.Error {
        case invalidResponse
        case httpStatus(Int)
        case timeout
        case emptyResponse
    }

    public let sourceURL: URL
    private let session: URLSession
    private let timeout: TimeInterval?

    public init(
        sourceURL: URL = MP4RARegistryEndpoints.boxes, session: URLSession = .shared,
        timeout: TimeInterval? = 30
    ) {
        self.sourceURL = sourceURL
        self.session = session
        self.timeout = timeout
    }

    public func fetchRegistryPayload() throws -> Data {
        let resultBox = MP4RAFetchResultBox()
        let semaphore = DispatchSemaphore(value: 0)
        let task = session.dataTask(with: sourceURL) { data, response, error in
            if let error = error {
                resultBox.value = .failure(error)
            } else if let data = data, let response = response {
                resultBox.value = .success((data, response))
            } else {
                resultBox.value = .failure(Error.emptyResponse)
            }
            semaphore.signal()
        }
        task.resume()

        if let timeout {
            let waitResult = semaphore.wait(timeout: .now() + timeout)
            if waitResult == .timedOut {
                task.cancel()
                throw Error.timeout
            }
        } else {
            semaphore.wait()
        }

        switch resultBox.value {
        case .success(let payload):
            guard let httpResponse = payload.1 as? HTTPURLResponse else {
                throw Error.invalidResponse
            }
            guard 200..<300 ~= httpResponse.statusCode else {
                throw Error.httpStatus(httpResponse.statusCode)
            }
            guard !payload.0.isEmpty else { throw Error.emptyResponse }
            return payload.0
        case .failure(let error): throw error
        case .none: throw Error.emptyResponse
        }
    }
}

// @todo #311 Split MP4RACatalogRefresher into smaller components to satisfy type_body_length
// swiftlint:disable:next type_body_length
public struct MP4RACatalogRefresher {
    public struct Catalog: Codable, Equatable {
        public struct Metadata: Codable, Equatable {
            public let source: String
            public let fetchedAt: String
            public let recordCount: Int
        }

        public struct Entry: Codable, Equatable {
            public let type: String
            public let uuid: String?
            public let name: String
            public let summary: String
            public let category: String?
            public let specification: String?
            public let version: Int?
            public let flags: String?
        }

        public let metadata: Metadata
        public let boxes: [Entry]
    }

    private struct RemoteRecord: Decodable {
        let code: String
        let description: String
        let specification: String?
        let handler: String?
        let category: String?
        let objectType: String?

        enum CodingKeys: String, CodingKey {
            case code
            case description
            case specification
            case handler
            case category = "type"
            case objectType = "ObjectType"
        }
    }

    private let dataProvider: MP4RARegistryDataProvider
    private let clock: () -> Date
    private let isoFormatter: ISO8601DateFormatter

    public init(dataProvider: MP4RARegistryDataProvider, clock: @escaping () -> Date = Date.init) {
        self.dataProvider = dataProvider
        self.clock = clock
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        self.isoFormatter = formatter
    }

    public func makeCatalog(baseline: Catalog? = nil) throws -> Catalog {
        let payload = try dataProvider.fetchRegistryPayload()
        let decoder = JSONDecoder()
        let remoteRecords = try decoder.decode([RemoteRecord].self, from: payload)

        var selected: [String: Catalog.Entry] = [:]
        for record in remoteRecords {
            guard let code = decodeFourCC(from: record.code) else { continue }
            let name = makeName(from: record.description)
            let summary = makeSummary(from: record)
            let specification = sanitized(record.specification)
            let category = sanitized(record.category)
            let entry = Catalog.Entry(
                type: code, uuid: nil, name: name, summary: summary, category: category,
                specification: specification, version: nil, flags: nil)

            if let existing = selected[code] {
                if shouldReplace(existing: existing, with: entry) { selected[code] = entry }
            } else {
                selected[code] = entry
            }
        }

        if let baseline { selected = merge(selected, withBaseline: baseline) }

        let boxes = selected.values.sorted { lhs, rhs in lhs.type < rhs.type }
        let metadata = Catalog.Metadata(
            source: dataProvider.sourceURL.absoluteString,
            fetchedAt: isoFormatter.string(from: clock()), recordCount: boxes.count)
        return Catalog(metadata: metadata, boxes: boxes)
    }

    @discardableResult public func writeCatalog(to url: URL) throws -> Catalog {
        let baseline = loadBaselineCatalog(at: url)
        let catalog = try makeCatalog(baseline: baseline)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(catalog)
        try data.write(to: url, options: .atomic)
        return catalog
    }

    private func loadBaselineCatalog(at url: URL) -> Catalog? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            if let catalog = try? decoder.decode(Catalog.self, from: data) { return catalog }
            if let legacy = try? decoder.decode(LegacyCatalog.self, from: data) {
                let entries = legacy.boxes.map { entry -> Catalog.Entry in
                    Catalog.Entry(
                        type: entry.type, uuid: entry.uuid, name: entry.name,
                        summary: entry.summary, category: nil, specification: entry.specification,
                        version: entry.version, flags: entry.flags)
                }
                return Catalog(
                    metadata: Catalog.Metadata(
                        source: "legacy", fetchedAt: "", recordCount: entries.count), boxes: entries
                )
            }
            return nil
        } catch { return nil }
    }

    private func decodeFourCC(from rawCode: String) -> String? {
        var output = ""
        var index = rawCode.startIndex
        while index < rawCode.endIndex {
            let character = rawCode[index]
            if character == "$" {
                let start = rawCode.index(after: index)
                let end =
                    rawCode.index(start, offsetBy: 2, limitedBy: rawCode.endIndex)
                    ?? rawCode.endIndex
                guard end <= rawCode.endIndex else { return nil }
                let hexString = String(rawCode[start..<end])
                guard hexString.count == 2, let value = UInt8(hexString, radix: 16),
                    let scalar = UnicodeScalar(Int(value))
                else { return nil }
                output.append(Character(scalar))
                index = end
                continue
            }

            if character == " " || character == "\t" || character == "\n" || character == "\r" {
                index = rawCode.index(after: index)
                continue
            }

            output.append(character)
            index = rawCode.index(after: index)
        }

        guard output.utf8.count == 4 else { return nil }
        return output
    }

    private func makeSummary(from record: RemoteRecord) -> String {
        let base = collapseWhitespace(record.description)
        var components: [String] = []
        if let handler = sanitized(record.handler) { components.append("handler: \(handler)") }
        if let category = sanitized(record.category) { components.append("category: \(category)") }
        if let objectType = sanitized(record.objectType) {
            components.append("objectType: \(objectType)")
        }
        guard !components.isEmpty else { return base }
        return "\(base) (\(components.joined(separator: ", ")))"
    }

    private func makeName(from description: String) -> String {
        let collapsed = collapseWhitespace(description)
        guard !collapsed.isEmpty else { return "" }
        let words = collapsed.split(separator: " ")
        return words.map { word -> String in
            let token = String(word)
            if token.allSatisfy({ !$0.isLetter || $0.isUppercase }) { return token }
            guard let first = token.first else { return token }
            return String(first).uppercased() + token.dropFirst()
        }.joined(separator: " ")
    }

    private func collapseWhitespace(_ text: String) -> String {
        text.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    private func merge(_ selected: [String: Catalog.Entry], withBaseline baseline: Catalog)
        -> [String: Catalog.Entry]
    {
        var merged = selected
        for entry in baseline.boxes {
            if let existing = merged[entry.type] {
                merged[entry.type] = merge(remote: existing, baseline: entry)
            } else {
                merged[entry.type] = entry
            }
        }
        return merged
    }

    private func merge(remote: Catalog.Entry, baseline: Catalog.Entry) -> Catalog.Entry {
        let uuid = remote.uuid ?? baseline.uuid
        let preferBaselineDetails = remote.uuid == nil && baseline.uuid != nil
        return Catalog.Entry(
            type: remote.type, uuid: uuid,
            name: preferBaselineDetails ? baseline.name : preferredName(remote.name, baseline.name),
            summary: preferBaselineDetails
                ? baseline.summary : preferredSummary(remote.summary, baseline.summary),
            category: remote.category ?? baseline.category,
            specification: preferBaselineDetails
                ? baseline.specification
                : preferredSpecification(remote.specification, baseline.specification),
            version: remote.version ?? baseline.version, flags: remote.flags ?? baseline.flags)
    }

    private func preferredName(_ remote: String, _ baseline: String) -> String {
        let trimmedRemote = collapseWhitespace(remote)
        if trimmedRemote.isEmpty { return collapseWhitespace(baseline) }
        return trimmedRemote
    }

    private func preferredSummary(_ remote: String, _ baseline: String) -> String {
        let trimmedRemote = collapseWhitespace(remote)
        let trimmedBaseline = collapseWhitespace(baseline)
        if trimmedRemote.isEmpty { return trimmedBaseline }
        if trimmedBaseline.isEmpty { return trimmedRemote }
        if trimmedRemote.count >= trimmedBaseline.count { return trimmedRemote }
        return trimmedBaseline
    }

    private func preferredSpecification(_ remote: String?, _ baseline: String?) -> String? {
        let trimmedRemote = remote.flatMap { value -> String in
            let collapsed = collapseWhitespace(value)
            return collapsed
        }
        let trimmedBaseline = baseline.flatMap { value -> String in
            let collapsed = collapseWhitespace(value)
            return collapsed
        }

        switch (trimmedRemote?.isEmpty ?? true, trimmedBaseline?.isEmpty ?? true) {
        case (false, true): return trimmedRemote
        case (true, false): return trimmedBaseline
        case (false, false):
            if (trimmedRemote?.count ?? 0) >= (trimmedBaseline?.count ?? 0) { return trimmedRemote }
            return trimmedBaseline
        default: return nil
        }
    }

    private func sanitized(_ value: String?) -> String? {
        guard let value = value else { return nil }
        let collapsed = collapseWhitespace(value)
        return collapsed.isEmpty ? nil : collapsed
    }

    private func shouldReplace(existing: Catalog.Entry, with candidate: Catalog.Entry) -> Bool {
        let existingHasSpec = !(existing.specification?.isEmpty ?? true)
        let candidateHasSpec = !(candidate.specification?.isEmpty ?? true)
        if !existingHasSpec && candidateHasSpec { return true }

        let existingHasDetails = existing.summary.contains("(")
        let candidateHasDetails = candidate.summary.contains("(")
        if !existingHasDetails && candidateHasDetails { return true }

        return false
    }
}

private struct LegacyCatalog: Decodable {
    struct Entry: Decodable {
        let type: String
        let uuid: String?
        let name: String
        let summary: String
        let specification: String?
        let version: Int?
        let flags: String?
    }

    let boxes: [Entry]
}
