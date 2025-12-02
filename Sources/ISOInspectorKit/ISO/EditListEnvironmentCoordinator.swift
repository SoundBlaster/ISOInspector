import Foundation

final class EditListEnvironmentCoordinator: @unchecked Sendable {
    private struct TrackContext {
        var trackID: UInt32?
        var mediaTimescale: UInt32?
    }

    private var movieTimescale: UInt32?
    private var trackStack: [TrackContext] = []
    private var cachedMediaTimescales: [UInt32: UInt32] = [:]

    func willStartBox(header: BoxHeader) {
        if header.type == BoxType.track { trackStack.append(TrackContext()) }
    }

    func didParsePayload(header: BoxHeader, payload: ParsedBoxPayload?) {
        switch header.type {
        case BoxType.movieHeader:
            if let movie = payload?.movieHeader { movieTimescale = movie.timescale }
        case BoxType.trackHeader:
            if let lastIndex = trackStack.indices.last, let detail = payload?.trackHeader {
                trackStack[lastIndex].trackID = detail.trackID
            }
        case BoxType.mediaHeader:
            guard let lastIndex = trackStack.indices.last else { return }
            guard let value = payload?.fields.first(where: { $0.name == "timescale" })?.value,
                let timescale = UInt32(value)
            else { return }
            trackStack[lastIndex].mediaTimescale = timescale
            if let trackID = trackStack[lastIndex].trackID {
                cachedMediaTimescales[trackID] = timescale
            }
        default: break
        }
    }

    func environment(for header: BoxHeader) -> BoxParserRegistry.EditListEnvironment {
        var environment = BoxParserRegistry.EditListEnvironment(movieTimescale: movieTimescale)
        guard header.type == BoxType.editList else { return environment }
        if let lastIndex = trackStack.indices.last {
            if let timescale = trackStack[lastIndex].mediaTimescale {
                environment.mediaTimescale = timescale
            } else if let trackID = trackStack[lastIndex].trackID,
                let cached = cachedMediaTimescales[trackID]
            {
                environment.mediaTimescale = cached
            }
        }
        return environment
    }

    func didFinishBox(header: BoxHeader) {
        if header.type == BoxType.track {
            if let finished = trackStack.popLast(), let trackID = finished.trackID,
                let timescale = finished.mediaTimescale
            {
                cachedMediaTimescales[trackID] = timescale
            }
        }
    }

    private enum BoxType {
        static let track = try! FourCharCode("trak")
        static let movieHeader = try! FourCharCode("mvhd")
        static let trackHeader = try! FourCharCode("tkhd")
        static let mediaHeader = try! FourCharCode("mdhd")
        static let editList = try! FourCharCode("elst")
    }
}
