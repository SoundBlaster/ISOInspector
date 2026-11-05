import ISOInspectorKit

protocol PayloadAnnotationProvider: Sendable {
    func annotations(for header: BoxHeader) async throws -> [PayloadAnnotation]
}
