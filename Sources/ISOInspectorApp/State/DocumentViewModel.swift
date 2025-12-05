#if canImport(Combine)
    import Combine
    import Foundation
    import ISOInspectorKit

    @MainActor final class DocumentViewModel: ObservableObject {
        struct ValidationSummary: Equatable {
            var errorCount: Int
            var warningCount: Int
            var infoCount: Int

            static func make(from snapshot: ParseTreeSnapshot) -> ValidationSummary {
                var errors = 0
                var warnings = 0
                var infos = 0
                for issue in snapshot.validationIssues {
                    switch issue.severity {
                    case .error: errors += 1
                    case .warning: warnings += 1
                    case .info: infos += 1
                    }
                }
                return ValidationSummary(
                    errorCount: errors, warningCount: warnings, infoCount: infos)
            }
        }

        struct ExportAvailability: Equatable {
            var canExportDocument: Bool
            var canExportSelection: Bool
        }

        @Published private(set) var snapshot: ParseTreeSnapshot
        @Published private(set) var parseState: ParseTreeStoreState
        @Published private(set) var validationSummary: ValidationSummary
        @Published private(set) var exportAvailability: ExportAvailability

        let outlineViewModel: ParseTreeOutlineViewModel
        let detailViewModel: ParseTreeDetailViewModel
        let nodeViewModel: NodeSelectionViewModel
        let hexViewModel: HexViewModel
        let annotations: AnnotationBookmarkSession
        let store: ParseTreeStore

        private var cancellables: Set<AnyCancellable> = []

        init(
            store: ParseTreeStore, annotations: AnnotationBookmarkSession,
            outlineViewModel: ParseTreeOutlineViewModel? = nil,
            detailViewModel: ParseTreeDetailViewModel? = nil
        ) {
            self.store = store
            self.annotations = annotations
            let resolvedOutline = outlineViewModel ?? ParseTreeOutlineViewModel()
            let resolvedDetail =
                detailViewModel
                ?? ParseTreeDetailViewModel(hexSliceProvider: nil, annotationProvider: nil)
            self.outlineViewModel = resolvedOutline
            self.detailViewModel = resolvedDetail
            self.hexViewModel = HexViewModel(detailViewModel: resolvedDetail)
            self.nodeViewModel = NodeSelectionViewModel(
                outlineViewModel: resolvedOutline, detailViewModel: resolvedDetail,
                annotations: annotations)
            self.snapshot = store.snapshot
            self.parseState = store.state
            self.validationSummary = ValidationSummary.make(from: store.snapshot)
            self.exportAvailability = ExportAvailability(
                canExportDocument: !store.snapshot.nodes.isEmpty, canExportSelection: false)

            setupBindings()
        }

        private func setupBindings() {
            annotations.setFileURL(store.fileURL)
            refreshDetailProviders()
            outlineViewModel.apply(snapshot: snapshot)
            detailViewModel.apply(snapshot: snapshot)
            nodeViewModel.handleSnapshotUpdate(snapshot: snapshot)
            updateExportAvailability()

            store.$snapshot.sink { [weak self] newSnapshot in
                self?.handleSnapshotUpdate(newSnapshot)
            }.store(in: &cancellables)

            store.$state.sink { [weak self] newState in
                guard let self else { return }
                self.parseState = newState
                self.refreshDetailProviders()
            }.store(in: &cancellables)

            store.$fileURL.sink { [weak self] fileURL in self?.annotations.setFileURL(fileURL) }
                .store(in: &cancellables)

            nodeViewModel.selectionPublisher.sink { [weak self] _ in
                self?.updateExportAvailability()
            }.store(in: &cancellables)
        }

        private func handleSnapshotUpdate(_ snapshot: ParseTreeSnapshot) {
            self.snapshot = snapshot
            outlineViewModel.apply(snapshot: snapshot)
            detailViewModel.apply(snapshot: snapshot)
            nodeViewModel.handleSnapshotUpdate(snapshot: snapshot)
            validationSummary = ValidationSummary.make(from: snapshot)
            updateExportAvailability()
        }

        private func refreshDetailProviders() {
            detailViewModel.update(
                hexSliceProvider: store.makeHexSliceProvider(),
                annotationProvider: store.makePayloadAnnotationProvider())
        }

        private func updateExportAvailability() {
            let canExportDocument = !snapshot.nodes.isEmpty
            let canExportSelection: Bool
            if let nodeID = nodeViewModel.selectedNodeID {
                canExportSelection = snapshot.containsNode(with: nodeID)
            } else {
                canExportSelection = false
            }
            exportAvailability = ExportAvailability(
                canExportDocument: canExportDocument, canExportSelection: canExportSelection)
        }
    }
#endif
