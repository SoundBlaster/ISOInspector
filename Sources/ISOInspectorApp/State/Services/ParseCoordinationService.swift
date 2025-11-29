#if canImport(SwiftUI) && canImport(Combine)
  import Foundation
  import ISOInspectorKit

  /// Service responsible for coordinating the parse pipeline and document opening.
  ///
  /// This service handles:
  /// - Background work queue coordination
  /// - Parse pipeline and reader factory management
  /// - Document opening workflow coordination
  @MainActor
  final class ParseCoordinationService {
    // MARK: - Properties

    private let pipelineFactory: @Sendable () -> ParsePipeline
    private let readerFactory: @Sendable (URL) throws -> RandomAccessReader
    private let workQueue: DocumentSessionWorkQueue

    // MARK: - Initialization

    init(
      pipelineFactory: @escaping @Sendable () -> ParsePipeline = { .live(options: .tolerant) },
      readerFactory: @escaping @Sendable (URL) throws -> RandomAccessReader = {
        try ChunkedFileReader(fileURL: $0)
      },
      workQueue: DocumentSessionWorkQueue = DocumentSessionBackgroundQueue()
    ) {
      self.pipelineFactory = pipelineFactory
      self.readerFactory = readerFactory
      self.workQueue = workQueue
    }

    // MARK: - Public Methods

    /// Initiates document opening on the background work queue.
    func openDocument(
      accessContext: AccessContext,
      failureRecent: DocumentRecent?,
      onSuccess: @escaping @MainActor @Sendable (
        SecurityScopedURL, Data?, BookmarkPersistenceStore.Record?, RandomAccessReader,
        ParsePipeline, DocumentRecent, Int64?
      ) -> Void,
      onFailure: @escaping @MainActor @Sendable (DocumentRecent, Error) -> Void,
      restoredSelection: Int64? = nil,
      preResolvedScope: SecurityScopedURL? = nil
    ) {
      let readerFactory = self.readerFactory
      let pipelineFactory = self.pipelineFactory

      workQueue.execute {
        do {
          let reader = try readerFactory(accessContext.scopedURL.url)
          let pipeline = pipelineFactory()

          Task { @MainActor in
            onSuccess(
              accessContext.scopedURL,
              accessContext.bookmarkData,
              accessContext.bookmarkRecord,
              reader,
              pipeline,
              accessContext.recent,
              restoredSelection
            )
          }
        } catch let accessError as DocumentAccessError {
          preResolvedScope?.revoke()
          accessContext.scopedURL.revoke()
          let targetRecent = failureRecent ?? accessContext.recent
          Task { @MainActor in
            onFailure(targetRecent, accessError)
          }
        } catch {
          preResolvedScope?.revoke()
          accessContext.scopedURL.revoke()
          let targetRecent = failureRecent ?? accessContext.recent
          Task { @MainActor in
            onFailure(targetRecent, error)
          }
        }
      }
    }
  }

#endif
