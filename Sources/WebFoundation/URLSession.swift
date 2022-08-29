import Foundation
import JavaScriptEventLoop
import JavaScriptKit

public class URLSession {
    public static let shared = URLSession()

    @available(
        *,
        unavailable,
        message: "URLSessionConfiguration is not yet supported in WebFoundation. Use `URLSession.shared` instead."
    )
    public init(configuration _: Any) {}

    private init() {
        JavaScriptEventLoop.installGlobalExecutor()
    }

    private let jsFetch = JSObject.global.fetch.function!
    private func fetch(request: URLRequest, corsMode: CORSMode) -> JSPromise {
        let urlString = request.url?.absoluteString
        let options = request.fetchRequest(corsMode: corsMode)
        return JSPromise(jsFetch(urlString, options).object!)!
    }

    // MARK: - Download data -

    /// Convenience method to load data using an URLRequest.
    ///
    /// - Parameter request: The URLRequest for which to load data.
    /// - Parameter corsMode: Cross-origin mode of the request (allows CORS by default).
    /// - Returns: Data and response.
    public func data(for request: URLRequest, corsMode: CORSMode = .cors) async throws -> (Data, URLResponse) {
        let fetchResponse = try await fetch(request: request, corsMode: corsMode).value
        let response = HTTPURLResponse(fetchResponse: fetchResponse, url: request.url!)
        let buffer = try await JSPromise(fetchResponse.arrayBuffer().object!)!.value.object!
        let byteArray = UInt8.typedArrayClass.new(buffer)
        let typed = JSTypedArray<UInt8>(unsafelyWrapping: byteArray)
        let data = typed.toData()
        return (data, response)
    }

    @available(*, unavailable, message: "Passing a delegate is not yet supported in WebFoundation.")
    public func data(for _: URLRequest, delegate _: Any?) async throws {
        fatalError()
    }

    /// Convenience method to load data using an URL.
    ///
    /// - Parameter url: The URL for which to load data.
    /// - Parameter corsMode: Cross-origin mode of the request (allows CORS by default).
    /// - Returns: Data and response.
    public func data(from url: URL, corsMode: CORSMode = .cors) async throws -> (Data, URLResponse) {
        try await data(for: URLRequest(url: url), corsMode: corsMode)
    }

    @available(*, unavailable, message: "Passing a delegate is not yet supported in WebFoundation")
    public func data(from url: URL, delegate _: Any?) async throws -> (Data, URLResponse) {
        try await data(for: URLRequest(url: url))
    }

    // MARK: - Upload Data -

    /// Uploads data to a URL based on the specified URL request and delivers the result asynchronously.
    ///
    /// - Parameter request: The URLRequest for which to upload data.
    /// - Parameter bodyData: Data to upload.
    /// - Parameter corsMode: Cross-origin mode of the request (allows CORS by default).
    /// - Returns: Data and response.
    public func upload(
        for request: URLRequest,
        from bodyData: Data,
        corsMode: CORSMode = .cors
    ) async throws -> (Data, URLResponse) {
        var request = request
        request.httpBody = bodyData
        return try await data(for: request, corsMode: corsMode)
    }

    @available(*, unavailable, message: "Passing a delegate is not yet supported in WebFoundation")
    public func upload(for _: URLRequest, from _: Data, delegate _: Any?) async throws -> (Data, URLResponse) {
        fatalError()
    }
}

/// The cross-origin behavior of the request.
/// See: https://developer.mozilla.org/en-US/docs/Web/API/Request/mode#value
public enum CORSMode: String {
    /// Allows cross-origin requests, for example to access various APIs offered by 3rd party vendors.
    /// These are expected to adhere to the [CORS protocol](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS).
    /// Only a [limited set](https://fetch.spec.whatwg.org/#concept-filtered-response-cors) of headers are exposed in
    /// the Response, but the body is readable.
    case cors

    /// Prevents the method from being anything other than HEAD, GET or POST, and the headers from being
    /// anything other than [simple headers](https://fetch.spec.whatwg.org/#simple-header).
    case noCORS = "no-cors"

    /// If a request is made to another origin with this mode set, the result is an error.
    /// You could use this to ensure that a request is always being made to your origin.
    case sameOrigin = "same-origin"
}

private extension URLRequest {
    func fetchRequest(corsMode: CORSMode) -> JSObject {
        let objectConstructor = JSObject.global.Object.function!
        let request = objectConstructor.new()
        request.method = httpMethod.jsValue

        // Headers
        let headers = objectConstructor.new()
        for (key, value) in allHTTPHeaderFields ?? [:] {
            headers[key] = value.jsValue
        }
        request.headers = .object(headers)

        // Request body
        if let body = httpBody {
            request.body = .object(body.blob())
        }

        // CORS
        request.mode = corsMode.rawValue.jsValue
        return request
    }
}

extension HTTPURLResponse {
    convenience init(fetchResponse: JSValue, url: URL) {
        var headerFields = [String: String]()
        let handleHeader = JSClosure { keyValuePair in
            headerFields[keyValuePair[1].string!] = keyValuePair[0].string!
            return .undefined
        }
        _ = fetchResponse.headers.forEach(handleHeader)

        // Force unwrapping: failable initializer doesn't actually have a fail path
        self.init(
            url: url,
            statusCode: Int(fetchResponse.status.number!),
            httpVersion: nil,
            headerFields: headerFields
        )!
    }
}
