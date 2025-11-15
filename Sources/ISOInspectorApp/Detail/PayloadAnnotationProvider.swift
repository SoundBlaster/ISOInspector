import ISOInspectorKit

protocol PayloadAnnotationProvider {
  func annotations(for header: BoxHeader) async throws -> [PayloadAnnotation]
}
