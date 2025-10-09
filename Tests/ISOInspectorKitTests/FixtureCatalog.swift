import Foundation
@testable import ISOInspectorKit

struct FixtureCatalog: Decodable {
// @todo #8 Expand fixture catalog with fragmented, DASH, and malformed media samples plus expected validation notes once automation lands.
    struct Fixture: Decodable, Equatable {
        struct Resource: Decodable, Equatable {
            let name: String
            let `extension`: String
            let subdirectory: String?

            func url(in bundle: Bundle) throws -> URL {
                guard let url = bundle.url(
                    forResource: name,
                    withExtension: `extension`,
                    subdirectory: subdirectory
                ) else {
                    throw FixtureCatalogError.missingResource(name: name, extension: `extension`, subdirectory: subdirectory)
                }
                return url
            }
        }

        struct Expectations: Decodable, Equatable {
            let warnings: [String]
            let errors: [String]
        }

        struct Provenance: Decodable, Equatable {
            let source: String
        }

        let id: String
        let title: String
        let description: String
        let format: String
        let tags: [String]
        let resource: Resource
        let provenance: Provenance
        let expectations: Expectations

        func url(in bundle: Bundle) throws -> URL {
            if let url = try? resource.url(in: bundle) {
                return url
            }
            var fallback = FixtureCatalog.fixturesDirectory
            if let subdirectory = resource.subdirectory, !subdirectory.isEmpty {
                fallback.appendPathComponent(subdirectory, isDirectory: true)
            }
            fallback.appendPathComponent("\(resource.name).\(resource.extension)")
            if FileManager.default.fileExists(atPath: fallback.path) {
                return fallback
            }
            throw FixtureCatalogError.missingResource(name: resource.name, extension: resource.extension, subdirectory: resource.subdirectory)
        }
    }


    private static let fixturesDirectory: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appendingPathComponent("Fixtures")

    let fixtures: [Fixture]

    static func load(decoder: JSONDecoder = JSONDecoder(), bundle: Bundle = .module) throws -> FixtureCatalog {
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard let url = bundle.url(forResource: "catalog", withExtension: "json") else {
            throw FixtureCatalogError.catalogNotFound
        }
        let data = try Data(contentsOf: url)
        return try decoder.decode(FixtureCatalog.self, from: data)
    }

    func fixture(withID id: String) -> Fixture? {
        fixtures.first { $0.id == id }
    }
}

enum FixtureCatalogError: Swift.Error, Equatable {
    case catalogNotFound
    case missingResource(name: String, extension: String, subdirectory: String?)
}
