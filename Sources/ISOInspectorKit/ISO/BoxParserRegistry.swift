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

    public struct FragmentEnvironment: Sendable {
        public var trackID: UInt32?
        public var sampleDescriptionIndex: UInt32?
        public var defaultSampleDuration: UInt32?
        public var defaultSampleSize: UInt32?
        public var defaultSampleFlags: UInt32?
        public var baseDataOffset: UInt64?
        public var dataCursor: UInt64?
        public var nextDecodeTime: UInt64?
        public var baseDecodeTime: UInt64?
        public var baseDecodeTimeIs64Bit: Bool
        public var trackExtendsDefaults: ParsedBoxPayload.TrackExtendsDefaultsBox?
        public var trackFragmentHeader: ParsedBoxPayload.TrackFragmentHeaderBox?
        public var trackFragmentDecodeTime: ParsedBoxPayload.TrackFragmentDecodeTimeBox?
        public var runIndex: UInt32
        public var nextSampleNumber: UInt64

        public init(
            trackID: UInt32? = nil,
            sampleDescriptionIndex: UInt32? = nil,
            defaultSampleDuration: UInt32? = nil,
            defaultSampleSize: UInt32? = nil,
            defaultSampleFlags: UInt32? = nil,
            baseDataOffset: UInt64? = nil,
            dataCursor: UInt64? = nil,
            nextDecodeTime: UInt64? = nil,
            baseDecodeTime: UInt64? = nil,
            baseDecodeTimeIs64Bit: Bool = false,
            trackExtendsDefaults: ParsedBoxPayload.TrackExtendsDefaultsBox? = nil,
            trackFragmentHeader: ParsedBoxPayload.TrackFragmentHeaderBox? = nil,
            trackFragmentDecodeTime: ParsedBoxPayload.TrackFragmentDecodeTimeBox? = nil,
            runIndex: UInt32 = 0,
            nextSampleNumber: UInt64 = 1
        ) {
            self.trackID = trackID
            self.sampleDescriptionIndex = sampleDescriptionIndex
            self.defaultSampleDuration = defaultSampleDuration
            self.defaultSampleSize = defaultSampleSize
            self.defaultSampleFlags = defaultSampleFlags
            self.baseDataOffset = baseDataOffset
            self.dataCursor = dataCursor
            self.nextDecodeTime = nextDecodeTime
            self.baseDecodeTime = baseDecodeTime
            self.baseDecodeTimeIs64Bit = baseDecodeTimeIs64Bit
            self.trackExtendsDefaults = trackExtendsDefaults
            self.trackFragmentHeader = trackFragmentHeader
            self.trackFragmentDecodeTime = trackFragmentDecodeTime
            self.runIndex = runIndex
            self.nextSampleNumber = nextSampleNumber
        }
    }

    public struct RandomAccessEnvironment: Sendable {
        public struct TrackFragment: Sendable {
            public let order: UInt32
            public let detail: ParsedBoxPayload.TrackFragmentBox

            public init(order: UInt32, detail: ParsedBoxPayload.TrackFragmentBox) {
                self.order = order
                self.detail = detail
            }
        }

        public struct Fragment: Sendable {
            public let sequenceNumber: UInt32?
            public let trackFragments: [TrackFragment]

            public init(sequenceNumber: UInt32?, trackFragments: [TrackFragment]) {
                self.sequenceNumber = sequenceNumber
                self.trackFragments = trackFragments
            }
        }

        public var fragmentsByMoofOffset: [UInt64: Fragment]

        public init(fragmentsByMoofOffset: [UInt64: Fragment] = [:]) {
            self.fragmentsByMoofOffset = fragmentsByMoofOffset
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

    private static let defaultFragmentEnvironmentProvider:
        @Sendable (_ header: BoxHeader, _ reader: RandomAccessReader) -> FragmentEnvironment = { _, _ in
            FragmentEnvironment()
        }

    @TaskLocal
    private static var fragmentEnvironmentProviderOverride:
        (@Sendable (BoxHeader, RandomAccessReader) -> FragmentEnvironment)?

    static func resolveFragmentEnvironment(
        header: BoxHeader,
        reader: RandomAccessReader
    ) -> FragmentEnvironment {
        if let override = fragmentEnvironmentProviderOverride {
            return override(header, reader)
        }
        return defaultFragmentEnvironmentProvider(header, reader)
    }

    public static func withFragmentEnvironmentProvider<T>(
        _ provider: @escaping @Sendable (BoxHeader, RandomAccessReader) -> FragmentEnvironment,
        perform: () throws -> T
    ) rethrows -> T {
        try $fragmentEnvironmentProviderOverride.withValue(provider, operation: perform)
    }

    private static let defaultRandomAccessEnvironmentProvider:
        @Sendable (_ header: BoxHeader, _ reader: RandomAccessReader) -> RandomAccessEnvironment = { _, _ in
            RandomAccessEnvironment()
        }

    @TaskLocal
    private static var randomAccessEnvironmentProviderOverride:
        (@Sendable (BoxHeader, RandomAccessReader) -> RandomAccessEnvironment)?

    static func resolveRandomAccessEnvironment(
        header: BoxHeader,
        reader: RandomAccessReader
    ) -> RandomAccessEnvironment {
        if let override = randomAccessEnvironmentProviderOverride {
            return override(header, reader)
        }
        return defaultRandomAccessEnvironmentProvider(header, reader)
    }

    public static func withRandomAccessEnvironmentProvider<T>(
        _ provider: @escaping @Sendable (BoxHeader, RandomAccessReader) -> RandomAccessEnvironment,
        perform: () throws -> T
    ) rethrows -> T {
        try $randomAccessEnvironmentProviderOverride.withValue(provider, operation: perform)
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
