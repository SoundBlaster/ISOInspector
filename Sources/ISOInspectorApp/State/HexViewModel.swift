#if canImport(Combine)
import Combine
import Foundation
import ISOInspectorKit

@MainActor
final class HexViewModel: ObservableObject {
    @Published private(set) var hexSlice: HexSlice?
    @Published private(set) var annotations: [PayloadAnnotation] = []
    @Published private(set) var highlightedRange: Range<Int64>?
    @Published private(set) var errorMessage: String?

    private let detailViewModel: ParseTreeDetailViewModel
    private var cancellables: Set<AnyCancellable> = []

    init(detailViewModel: ParseTreeDetailViewModel) {
        self.detailViewModel = detailViewModel

        detailViewModel.$detail
            .map { $0?.hexSlice }
            .sink { [weak self] slice in
                self?.hexSlice = slice
            }
            .store(in: &cancellables)

        detailViewModel.$annotations
            .sink { [weak self] annotations in
                self?.annotations = annotations
            }
            .store(in: &cancellables)

        detailViewModel.$highlightedRange
            .sink { [weak self] range in
                self?.highlightedRange = range
            }
            .store(in: &cancellables)

        detailViewModel.$hexError
            .sink { [weak self] error in
                self?.errorMessage = error
            }
            .store(in: &cancellables)
    }

    func selectAnnotation(id: PayloadAnnotation.ID?) {
        detailViewModel.select(annotationID: id)
    }

    func selectByte(at offset: Int64) {
        detailViewModel.selectByte(at: offset)
    }
}
#endif
