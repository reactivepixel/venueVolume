import Foundation

public struct SyncPayload: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let requestID: UUID
    public let createdAt: Date
    public let revision: Int
    public let totalFixtures: Int
    public let totalChannels: Int
    public let fixtures: [Fixture]

    public init(fixtures: [Fixture], revision: Int) {
        schemaVersion = 1
        requestID = UUID()
        createdAt = Date()
        self.revision = revision
        totalFixtures = fixtures.count
        totalChannels = fixtures.reduce(0) { $0 + $1.channels.count }
        self.fixtures = fixtures
    }

    public func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }
}

public struct SyncReceipt: Codable, Sendable {
    public let requestID: UUID
    public let acceptedFixtures: Int
    public let acceptedChannels: Int
    public let revision: Int
    public let mock: Bool
}

public enum SyncError: LocalizedError {
    case rejected(Int)
    case invalidConfiguration(String)
    public var errorDescription: String? {
        switch self {
        case .rejected(let status): "Mock server returned HTTP \(status). Your configuration is unchanged; retry Sync."
        case .invalidConfiguration(let message): message
        }
    }
}

/// Uses URLSession's request/response path, intercepted locally. No network output.
public actor MockSyncClient {
    public static let endpoint = URL(string: "https://venue-volume.invalid/api/v1/dmx/configurations/sync")!
    private let session: URLSession

    public init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockSyncURLProtocol.self]
        session = URLSession(configuration: configuration)
    }

    public func send(_ payload: SyncPayload, simulateFailure: Bool = false) async throws -> SyncReceipt {
        for fixture in payload.fixtures {
            if let issue = fixture.validationIssue(among: payload.fixtures) {
                throw SyncError.invalidConfiguration(issue)
            }
        }
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(simulateFailure ? "true" : "false", forHTTPHeaderField: "X-Mock-Failure")
        request.httpBody = try payload.jsonData()
        try await Task.sleep(for: .milliseconds(450))
        let (data, response) = try await session.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else { throw SyncError.rejected(status) }
        return try JSONDecoder().decode(SyncReceipt.self, from: data)
    }
}

private final class MockSyncURLProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool {
        request.url?.host == "venue-volume.invalid"
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            var data = request.httpBody ?? Data()
            if data.isEmpty, let stream = request.httpBodyStream {
                stream.open()
                defer { stream.close() }
                var buffer = [UInt8](repeating: 0, count: 4096)
                while stream.hasBytesAvailable {
                    let count = stream.read(&buffer, maxLength: buffer.count)
                    if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
                    if count == 0 { break }
                    data.append(contentsOf: buffer.prefix(count))
                }
            }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let payload = try decoder.decode(SyncPayload.self, from: data)
            let status = request.value(forHTTPHeaderField: "X-Mock-Failure") == "true" ? 503 : 200
            let receipt = SyncReceipt(requestID: payload.requestID,
                                      acceptedFixtures: payload.fixtures.count,
                                      acceptedChannels: payload.fixtures.reduce(0) { $0 + $1.channels.count },
                                      revision: payload.revision, mock: true)
            let response = HTTPURLResponse(url: request.url!, statusCode: status,
                                           httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: try JSONEncoder().encode(receipt))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
