import Foundation
import XCTest

final class AppIconAssetTests: XCTestCase {
    func testAppIconManifestFilenamesMatchConvention() throws {
        let manifestURL = URL(fileURLWithPath: "Sources/ISOInspectorApp/Resources/Assets.xcassets/AppIcon.appiconset/Contents.json")
        let data = try Data(contentsOf: manifestURL)
        let manifest = try JSONDecoder().decode(AppIconManifest.self, from: data)

        XCTAssertFalse(manifest.images.isEmpty, "Expected app icon manifest to declare at least one image")

        let assetDirectory = manifestURL.deletingLastPathComponent()
        var seenFilenames = Set<String>()
        for image in manifest.images {
            let description = "idiom=\(image.idiom ?? "unknown"), size=\(image.size ?? "?"), scale=\(image.scale ?? "?")"
            guard let filename = image.filename, !filename.isEmpty else {
                XCTFail("App icon entry missing filename for \(description)")
                continue
            }

            let expectedFilename = expectedFilename(for: image)
            XCTAssertEqual(filename, expectedFilename, "Unexpected filename for \(description)")

            let inserted = seenFilenames.insert(filename).inserted
            XCTAssertTrue(inserted, "Duplicate filename detected for \(description) → \(filename)")

            // The raster PNGs are generated on demand and ignored by source control, so
            // only verify that the directory exists to hint if the asset catalog moved.
            XCTAssertTrue(FileManager.default.fileExists(atPath: assetDirectory.path), "Missing AppIcon.appiconset directory")
        }
    }
}

private struct AppIconManifest: Decodable {
    let images: [Image]

    struct Image: Decodable {
        let filename: String?
        let idiom: String?
        let scale: String?
        let size: String?
    }
}

private func expectedFilename(for image: AppIconManifest.Image) -> String {
    let idiom = image.idiom ?? "universal"
    let sizeLabel = (image.size ?? "0x0")
        .replacingOccurrences(of: " ", with: "")
        .replacingOccurrences(of: ".", with: "-")
    let scale = image.scale ?? "1x"
    return "AppIcon-\(idiom)-\(sizeLabel)@\(scale).png"
}
