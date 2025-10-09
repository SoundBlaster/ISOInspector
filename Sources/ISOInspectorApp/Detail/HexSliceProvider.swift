protocol HexSliceProvider {
    func loadSlice(for request: HexSliceRequest) async throws -> HexSlice
}
