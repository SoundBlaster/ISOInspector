import Foundation

public struct BoxParserRegistry: Sendable {
    public typealias Parser = @Sendable (_ header: BoxHeader, _ reader: RandomAccessReader) throws -> ParsedBoxPayload?

    private var typeParsers: [FourCharCode: Parser]
    private var extendedTypeParsers: [UUID: Parser]
    private let fallback: Parser

    public init(
        typeParsers: [FourCharCode: Parser] = [:],
        extendedTypeParsers: [UUID: Parser] = [:],
        fallback: Parser? = nil
    ) {
        self.typeParsers = typeParsers
        self.extendedTypeParsers = extendedTypeParsers
        self.fallback = fallback ?? BoxParserRegistry.placeholderFallback
    }

    public mutating func register(parser: @escaping Parser, for type: FourCharCode) {
        typeParsers[type] = parser
    }

    public mutating func register(parser: @escaping Parser, forExtendedType uuid: UUID) {
        extendedTypeParsers[uuid] = parser
    }

    public func parser(for header: BoxHeader) -> Parser {
        if let uuid = header.uuid, let parser = extendedTypeParsers[uuid] {
            return parser
        }
        if let parser = typeParsers[header.type] {
            return parser
        }
        return fallback
    }

    public func parse(header: BoxHeader, reader: RandomAccessReader) throws -> ParsedBoxPayload? {
        try parser(for: header)(header, reader)
    }

    private static let placeholderFallback: Parser = { header, _ in
        let payloadRange = header.payloadRange
        let payloadLength = max(0, payloadRange.upperBound - payloadRange.lowerBound)

        var fields: [ParsedBoxPayload.Field] = [
            ParsedBoxPayload.Field(
                name: "parser",
                value: "placeholder",
                description: "No parser registered for this box type; returning placeholder metadata."
            ),
            ParsedBoxPayload.Field(
                name: "payload_length",
                value: String(payloadLength),
                description: "Number of bytes in the box payload."
            )
        ]

        if payloadLength > 0 {
            fields.append(
                ParsedBoxPayload.Field(
                    name: "payload_range",
                    value: String(describing: payloadRange),
                    description: "Byte range of the payload relative to the file start.",
                    byteRange: payloadRange
                )
            )
        }

        return ParsedBoxPayload(fields: fields)
    }

    public struct EditListEnvironment: Sendable {
        public var movieTimescale: UInt32?
        public var mediaTimescale: UInt32?

        public init(movieTimescale: UInt32? = nil, mediaTimescale: UInt32? = nil) {
            self.movieTimescale = movieTimescale
            self.mediaTimescale = mediaTimescale
        }
    }

    public struct MetadataEnvironment: Sendable {
        public var handlerType: HandlerType?
        public var keyTable: [UInt32: ParsedBoxPayload.MetadataKeyTableBox.Entry]

        public init(
            handlerType: HandlerType? = nil,
            keyTable: [UInt32: ParsedBoxPayload.MetadataKeyTableBox.Entry] = [:]
        ) {
            self.handlerType = handlerType
            self.keyTable = keyTable
        }
    }

    private static let defaultEditListEnvironmentProvider:
        @Sendable (_ header: BoxHeader, _ reader: RandomAccessReader) -> EditListEnvironment = { _, _ in
            EditListEnvironment()
        }

    @TaskLocal
    private static var editListEnvironmentProviderOverride:
        (@Sendable (BoxHeader, RandomAccessReader) -> EditListEnvironment)?

    static func resolveEditListEnvironment(
        header: BoxHeader,
        reader: RandomAccessReader
    ) -> EditListEnvironment {
        if let override = editListEnvironmentProviderOverride {
            return override(header, reader)
        }
        return defaultEditListEnvironmentProvider(header, reader)
    }

    public static func withEditListEnvironmentProvider<T>(
        _ provider: @escaping @Sendable (BoxHeader, RandomAccessReader) -> EditListEnvironment,
        perform: () throws -> T
    ) rethrows -> T {
        try $editListEnvironmentProviderOverride.withValue(provider, operation: perform)
    }

    private static let defaultMetadataEnvironmentProvider:
        @Sendable (_ header: BoxHeader, _ reader: RandomAccessReader) -> MetadataEnvironment = { _, _ in
            MetadataEnvironment()
        }

    @TaskLocal
    private static var metadataEnvironmentProviderOverride:
        (@Sendable (BoxHeader, RandomAccessReader) -> MetadataEnvironment)?

    static func resolveMetadataEnvironment(
        header: BoxHeader,
        reader: RandomAccessReader
    ) -> MetadataEnvironment {
        if let override = metadataEnvironmentProviderOverride {
            return override(header, reader)
        }
        return defaultMetadataEnvironmentProvider(header, reader)
    }

    public static func withMetadataEnvironmentProvider<T>(
        _ provider: @escaping @Sendable (BoxHeader, RandomAccessReader) -> MetadataEnvironment,
        perform: () throws -> T
    ) rethrows -> T {
        try $metadataEnvironmentProviderOverride.withValue(provider, operation: perform)
    }

    public func registering(parser: @escaping Parser, for type: FourCharCode) -> BoxParserRegistry {
        var copy = self
        copy.register(parser: parser, for: type)
        return copy
    }

    public func registering(parser: @escaping Parser, forExtendedType uuid: UUID) -> BoxParserRegistry {
        var copy = self
        copy.register(parser: parser, forExtendedType: uuid)
        return copy
    }

    public static let shared: BoxParserRegistry = {
        var registry = BoxParserRegistry()
        DefaultParsers.registerAll(into: &registry)
        return registry
    }()
}
