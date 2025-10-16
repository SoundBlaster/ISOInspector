#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
import NestedA11yIDs

struct AppShellView: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject var controller: DocumentSessionController
    @State private var isImporterPresented = false
    @State private var importError: ImportError?

    @ViewBuilder
    var body: some View {
        if #available(iOS 17, macOS 14, *) {
            content
                .onChange(of: scenePhase, initial: false) { _, phase in
                    handleScenePhaseChange(phase)
                }
        } else {
            content
                .onChange(of: scenePhase) { phase in
                    handleScenePhaseChange(phase)
                }
        }
    }

    private var content: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .overlay(alignment: .top) {
            if let failure = controller.loadFailure {
                DocumentLoadFailureBanner(
                    failure: failure,
                    retryAction: controller.retryLastFailure,
                    dismissAction: controller.dismissLoadFailure,
                    openFileAction: { isImporterPresented = true }
                )
                .padding(.horizontal)
                .padding(.top)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: controller.loadFailure?.id)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: controller.allowedContentTypes,
            allowsMultipleSelection: false,
            onCompletion: handleImportResult
        )
        .alert(importError?.title ?? "", isPresented: importErrorBinding) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            if let message = importError?.message {
                Text(message)
            }
        }
        .onOpenURL { url in
            controller.openDocument(at: url)
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        if phase == .background || phase == .inactive {
            controller.parseTreeStore.shutdown()
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("ISO Inspector")
                    .font(.title2)
                    .bold()
                Text("Inspect MP4 and QuickTime files")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Button {
                isImporterPresented = true
            } label: {
                Label("Open File…", systemImage: "folder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)

            List {
                Section("Recents") {
                    if controller.recents.isEmpty {
                        Text("Choose a file to start building your recents list.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(controller.recents) { recent in
                            Button {
                                controller.openRecent(recent)
                            } label: {
                                RecentRow(recent: recent)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: controller.removeRecent)
                    }
                }
            }
            .listStyle(.sidebar)

            Spacer()
        }
        .padding()
        .nestedAccessibilityIdentifier(ParseTreeAccessibilityID.root)
    }

    private var detail: some View {
        Group {
            if controller.currentDocument != nil {
                ParseTreeExplorerView(
                    store: controller.parseTreeStore,
                    annotations: controller.annotations,
                    outlineViewModel: ParseTreeOutlineViewModel(),
                    detailViewModel: ParseTreeDetailViewModel(hexSliceProvider: nil, annotationProvider: nil)
                )
                .frame(minWidth: 640, minHeight: 480)
            } else {
                OnboardingView(openAction: { isImporterPresented = true })
            }
        }
    }

    private func handleImportResult(_ result: Result<[URL], Error>) {
        switch result {
        case let .success(urls):
            guard let url = urls.first else { return }
            controller.openDocument(at: url)
        case let .failure(error):
            importError = ImportError(title: "Failed to open file", message: error.localizedDescription)
        }
    }

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { newValue in
                if !newValue {
                    importError = nil
                }
            }
        )
    }
}

private struct DocumentLoadFailureBanner: View {
    let failure: DocumentSessionController.DocumentLoadFailure
    let retryAction: () -> Void
    let dismissAction: () -> Void
    let openFileAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 6) {
                    Text(failure.title)
                        .font(.headline)
                    Text(failure.message)
                        .font(.subheadline)
                    if let details = failure.details, !details.isEmpty {
                        Text(details)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Text(failure.recoverySuggestion)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .padding(6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss error")
            }

            HStack(spacing: 12) {
                Button("Try Again", action: retryAction)
                    .buttonStyle(.borderedProminent)
                Button("Open File…", action: openFileAction)
                    .buttonStyle(.bordered)
                Spacer()
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.red.opacity(0.35), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 14, y: 6)
        .accessibilityIdentifier("document-load-failure-banner")
    }
}

private struct RecentRow: View {
    let recent: DocumentRecent
    private let dateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(recent.displayName)
                .font(.headline)
            Text(formattedDate())
                .font(.caption)
                .foregroundColor(.secondary)
            Text(recent.url.path)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.7))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formattedDate() -> String {
        dateFormatter.localizedString(for: recent.lastOpened, relativeTo: Date())
    }
}

private struct OnboardingView: View {
    let openAction: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "film")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            VStack(spacing: 8) {
                Text("Open an MP4 or QuickTime file to begin")
                    .font(.title2)
                    .bold()
                Text("Use the Open File button to select a document. Recently opened files will appear in the sidebar for quick access.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            Button(action: openAction) {
                Label("Open File…", systemImage: "folder")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private struct ImportError: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
#endif
