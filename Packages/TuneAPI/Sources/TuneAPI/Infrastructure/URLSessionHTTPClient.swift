import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let request = URLRequest(url: url)
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RemoteSongRepositoryError.connectivity
            }
            return (data, httpResponse)
        } catch is RemoteSongRepositoryError {
            // TODO: the infrastructure should return plain ERROR and it is repository responsability to map the error accordinly. Fine for now - refactor later.
            throw RemoteSongRepositoryError.connectivity
        } catch {
            // TODO: can later define other error states based on specific errors
            throw RemoteSongRepositoryError.connectivity
        }
    }
}
