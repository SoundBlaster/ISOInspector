import Foundation
import Synchronization
import Testing

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@testable import ISOInspectorKit

@Suite struct HTTPMP4RARegistryDataProviderTests {
    @Test func cancellationInterruptsAnInFlightFetch() async throws {
        let (provider, session) = makeProvider(path: "cancel-test", timeout: 2)
        defer { session.invalidateAndCancel() }
        let (started, signal) = AsyncStream<Void>.makeStream()
        RegistryURLProtocol.startSignal.withLock { $0 = .active(signal) }
        defer {
            RegistryURLProtocol.startSignal.withLock { $0 = .inactive }
            signal.finish()
        }
        let task = Task { try await provider.fetchRegistryPayload() }
        let wasStarted = await withTaskGroup(of: Bool.self) { group in
            group.addTask { for await _ in started { return true }; return false }
            group.addTask {
                do { try await Task.sleep(for: .seconds(5)) } catch { return false }
                return false
            }
            let result = await group.next() ?? false
            group.cancelAll()
            return result
        }
        #expect(wasStarted)
        task.cancel()
        do {
            _ = try await task.value
            Issue.record("Expected cancellation")
        } catch is CancellationError {
        } catch {
            Issue.record("Expected cancellation, got \(error)")
        }
    }

    @Test(arguments: [200, 299])
    func returnsPayloadForSuccessfulHTTPStatus(status: Int) async throws {
        let (provider, session) = makeProvider(path: "status/\(status)")
        defer { session.invalidateAndCancel() }

        let result = try await provider.fetchRegistryPayload()

        #expect(result == Data("registry payload".utf8))
    }

    @Test(arguments: [199, 300, 404, 500])
    func rejectsUnsuccessfulHTTPStatus(status: Int) async throws {
        let (provider, session) = makeProvider(path: "status/\(status)")
        defer { session.invalidateAndCancel() }

        await #expect {
            try await provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.httpStatus(let actual) = error else {
                return false
            }
            return actual == status
        }
    }

    @Test func rejectsAnEmptySuccessfulResponse() async throws {
        let (provider, session) = makeProvider(path: "empty")
        defer { session.invalidateAndCancel() }

        await #expect {
            try await provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.emptyResponse = error else {
                return false
            }
            return true
        }
    }

    @Test func rejectsNonHTTPResponse() async throws {
        let (provider, session) = makeProvider(path: "non-http")
        defer { session.invalidateAndCancel() }

        await #expect {
            try await provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.invalidResponse = error else {
                return false
            }
            return true
        }
    }

    @Test func propagatesNetworkFailure() async throws {
        let (provider, session) = makeProvider(path: "network-error")
        defer { session.invalidateAndCancel() }

        await #expect {
            try await provider.fetchRegistryPayload()
        } throws: { error in
            (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    @Test func timesOutWhenTheRequestDoesNotComplete() async throws {
        let (provider, session) = makeProvider(path: "never-completes", timeout: 0.1)
        defer { session.invalidateAndCancel() }

        await #expect {
            try await provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.timeout = error else { return false }
            return true
        }
    }

    @Test func allowsAnUnlimitedTimeout() async throws {
        let (provider, session) = makeProvider(path: "status/200", timeout: nil)
        defer { session.invalidateAndCancel() }

        #expect(try await provider.fetchRegistryPayload() == Data("registry payload".utf8))
    }

    @Test func synchronousFetchRemainsAvailable() throws {
        let (provider, session) = makeProvider(path: "status/200")
        defer { session.invalidateAndCancel() }
        #expect(try provider.fetchRegistryPayload() == Data("registry payload".utf8))
    }

    @Test func synchronousFetchStillReportsNetworkFailure() throws {
        let (provider, session) = makeProvider(path: "network-error")
        defer { session.invalidateAndCancel() }
        #expect { try provider.fetchRegistryPayload() } throws: { error in
            (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    @Test func synchronousFetchStillTimesOut() throws {
        let (provider, session) = makeProvider(path: "never-completes", timeout: 0.1)
        defer { session.invalidateAndCancel() }
        #expect { try provider.fetchRegistryPayload() } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.timeout = error else { return false }
            return true
        }
    }

    private func makeProvider(path: String, timeout: TimeInterval? = 2)
        -> (HTTPMP4RARegistryDataProvider, URLSession)
    {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [RegistryURLProtocol.self]
        let session = URLSession(configuration: configuration)
        let url = URL(string: "https://mp4ra.test.invalid/\(path)")!
        return (HTTPMP4RARegistryDataProvider(sourceURL: url, session: session, timeout: timeout), session)
    }
}

private final class RegistryURLProtocol: URLProtocol {
    enum StartSignal: Sendable {
        case inactive
        case active(AsyncStream<Void>.Continuation)
    }
    static let startSignal = Mutex<StartSignal>(.inactive)
    override static func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "mp4ra.test.invalid"
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let client else { return }
        switch url.path {
        case "/cancel-test":
            Self.startSignal.withLock {
                if case .active(let signal) = $0 { signal.yield() }
            }
            return
        case "/never-completes": return
        case "/network-error":
            client.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
        case "/non-http":
            let response = URLResponse(url: url, mimeType: nil, expectedContentLength: 1, textEncodingName: nil)
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client.urlProtocol(self, didLoad: Data([1]))
            client.urlProtocolDidFinishLoading(self)
        default:
            let components = url.path.split(separator: "/")
            let status = components.first == "status" ? Int(components.last ?? "") ?? 500 : 200
            guard let response = HTTPURLResponse(
                url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)
            else { return }
            client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if url.path != "/empty" { client.urlProtocol(self, didLoad: Data("registry payload".utf8)) }
            client.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {}
}
