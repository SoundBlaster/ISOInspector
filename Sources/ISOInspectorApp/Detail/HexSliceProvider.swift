protocol HexSliceProvider: Sendable { func loadSlice(for request: HexSliceRequest) async throws -> HexSlice }
