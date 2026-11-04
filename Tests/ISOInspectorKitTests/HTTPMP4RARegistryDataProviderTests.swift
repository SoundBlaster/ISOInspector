import Foundation
import Testing

#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif

@testable import ISOInspectorKit

@Suite struct HTTPMP4RARegistryDataProviderTests {
    @Test(arguments: [200, 299])
    func returnsPayloadForSuccessfulHTTPStatus(status: Int) throws {
        let (provider, session) = makeProvider(path: "status/\(status)")
        defer { session.invalidateAndCancel() }

        let result = try provider.fetchRegistryPayload()

        #expect(result == Data("registry payload".utf8))
    }

    @Test(arguments: [199, 300, 404, 500])
    func rejectsUnsuccessfulHTTPStatus(status: Int) throws {
        let (provider, session) = makeProvider(path: "status/\(status)")
        defer { session.invalidateAndCancel() }

        #expect {
            try provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.httpStatus(let actual) = error else {
                return false
            }
            return actual == status
        }
    }

    @Test func rejectsAnEmptySuccessfulResponse() throws {
        let (provider, session) = makeProvider(path: "empty")
        defer { session.invalidateAndCancel() }

        #expect {
            try provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.emptyResponse = error else {
                return false
            }
            return true
        }
    }

    @Test func rejectsNonHTTPResponse() throws {
        let (provider, session) = makeProvider(path: "non-http")
        defer { session.invalidateAndCancel() }

        #expect {
            try provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.invalidResponse = error else {
                return false
            }
            return true
        }
    }

    @Test func propagatesNetworkFailure() throws {
        let (provider, session) = makeProvider(path: "network-error")
        defer { session.invalidateAndCancel() }

        #expect {
            try provider.fetchRegistryPayload()
        } throws: { error in
            (error as? URLError)?.code == .notConnectedToInternet
        }
    }

    @Test func timesOutWhenTheRequestDoesNotComplete() throws {
        let (provider, session) = makeProvider(path: "never-completes", timeout: 0.1)
        defer { session.invalidateAndCancel() }

        #expect {
            try provider.fetchRegistryPayload()
        } throws: { error in
            guard case HTTPMP4RARegistryDataProvider.Error.timeout = error else { return false }
            return true
        }
    }

    @Test func allowsAnUnlimitedTimeout() throws {
        let (provider, session) = makeProvider(path: "status/200", timeout: nil)
        defer { session.invalidateAndCancel() }

        #expect(try provider.fetchRegistryPayload() == Data("registry payload".utf8))
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
    override static func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "mp4ra.test.invalid"
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let client else { return }
        switch url.path {
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
