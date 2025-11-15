import Foundation

public struct DistributionMetadata: Codable, Equatable {
  public struct Target: Codable, Equatable {
    public enum Platform: String, Codable {
      case macOS
      case iOS
      case iPadOS
    }

    public let platform: Platform
    public let productName: String
    public let bundleIdentifier: String
    public let entitlementsPath: String
  }

  public let marketingVersion: String
  public let buildNumber: String
  public let teamIdentifier: String
  public let targets: [Target]
}

public enum DistributionMetadataLoader {
  private static let resourceFileName = "DistributionMetadata"
  private static let resourceExtension = "json"
  public static func defaultMetadata() throws -> DistributionMetadata {
    let bundle = Bundle.module
    let resourceURL =
      bundle.url(
        forResource: resourceFileName,
        withExtension: resourceExtension,
        subdirectory: "Distribution"
      )
      ?? bundle.url(
        forResource: resourceFileName,
        withExtension: resourceExtension
      )

    guard let url = resourceURL else {
      throw DistributionMetadataError.resourceNotFound
    }
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(DistributionMetadata.self, from: data)
  }
}

public enum DistributionMetadataError: Error {
  case resourceNotFound
}
