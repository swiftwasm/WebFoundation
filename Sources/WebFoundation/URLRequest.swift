//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2016 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See http://swift.org/LICENSE.txt for license information
// See http://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

import Foundation

public struct URLRequest: Equatable, Hashable {
    /// Creates and initializes a URLRequest with the given URL and cache policy.
    /// - parameter url: The URL for the request.
    /// - parameter cachePolicy: The cache policy for the request. Defaults to `.useProtocolCachePolicy`
    /// - parameter timeoutInterval: The timeout interval for the request. See the commentary for the `timeoutInterval`
    /// for more information on timeout intervals. Defaults to 60.0
    public init(url: URL, cachePolicy: CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 60.0) {
        self.url = url.absoluteURL
        self.cachePolicy = cachePolicy
        self.timeoutInterval = timeoutInterval
    }

    /// The URL of the receiver.
    public var url: URL?

    /// The cache policy of the receiver.
    public var cachePolicy: CachePolicy

    // URLRequest.timeoutInterval should be given precedence over the URLSessionConfiguration.timeoutIntervalForRequest
    // regardless of the value set, if it has been set at least once. Even though the default value is 60, if the user
    // sets URLRequest.timeoutInterval to explicitly 60, then the precedence should be given to
    // URLRequest.timeoutInterval.
    internal var isTimeoutIntervalSet = false

    /// Returns the timeout interval of the receiver.
    /// - discussion: The timeout interval specifies the limit on the idle
    /// interval allotted to a request in the process of loading. The "idle
    /// interval" is defined as the period of time that has passed since the
    /// last instance of load activity occurred for a request that is in the
    /// process of loading. Hence, when an instance of load activity occurs
    /// (e.g. bytes are received from the network for a request), the idle
    /// interval for a request is reset to 0. If the idle interval ever
    /// becomes greater than or equal to the timeout interval, the request
    /// is considered to have timed out. This timeout interval is measured
    /// in seconds.
    public var timeoutInterval: TimeInterval {
        didSet {
            isTimeoutIntervalSet = true
        }
    }

    /// The main document URL associated with this load.
    /// - discussion: This URL is used for the cookie "same domain as main
    /// document" policy.
    public var mainDocumentURL: URL?

    /// The URLRequest.NetworkServiceType associated with this request.
    /// Cannot be set using browser Fetch.
    public let networkServiceType: NetworkServiceType = .default

    /// `true` if the receiver is allowed to use the built in cellular radios to
    /// satisfy the request, `false` otherwise.
    /// Cannot be set using browser Fetch.
    public let allowsCellularAccess = true

    private var _httpMethod: String? = "GET"

    /// The HTTP request method of the receiver.
    public var httpMethod: String? {
        get { _httpMethod }
        set { _httpMethod = URLRequest._normalized(httpMethod: newValue) }
    }

    private static func _normalized(httpMethod raw: String?) -> String {
        guard let raw = raw else {
            return "GET"
        }

        let nsMethod = NSString(string: raw)

        for method in ["GET", "HEAD", "POST", "PUT", "DELETE", "CONNECT"] {
            if nsMethod.caseInsensitiveCompare(method) == .orderedSame {
                return method
            }
        }
        return raw
    }

    /// A dictionary containing all the HTTP header fields of the
    /// receiver.
    public var allHTTPHeaderFields: [String: String]?

    /// Returns the value which corresponds to the given header field.
    ///
    /// Note that, in keeping with the HTTP RFC, HTTP header field
    /// names are case-insensitive.
    /// - Parameter field: the header field name to use for the lookup
    ///     (case-insensitive).
    /// - Returns: the value associated with the given header field, or `nil` if
    /// there is no value associated with the given header field.
    public func value(forHTTPHeaderField field: String) -> String? {
        guard let f = allHTTPHeaderFields else { return nil }
        return existingHeaderField(field, inHeaderFields: f)?.1
    }

    /// Sets the value of the given HTTP header field.
    ///
    /// If a value was previously set for the given header
    /// field, that value is replaced with the given value. Note that, in
    /// keeping with the HTTP RFC, HTTP header field names are
    /// case-insensitive.
    /// - Parameter value: the header field value.
    /// - Parameter field: the header field name (case-insensitive).
    public mutating func setValue(_ value: String?, forHTTPHeaderField field: String) {
        // Store the field name capitalized to match native Foundation
        let capitalizedFieldName = field.capitalized
        var f: [String: String] = allHTTPHeaderFields ?? [:]
        if let old = existingHeaderField(capitalizedFieldName, inHeaderFields: f) {
            f.removeValue(forKey: old.0)
        }
        f[capitalizedFieldName] = value
        allHTTPHeaderFields = f
    }

    /// Adds an HTTP header field in the current header dictionary.
    ///
    /// This method provides a way to add values to header
    /// fields incrementally. If a value was previously set for the given
    /// header field, the given value is appended to the previously-existing
    /// value. The appropriate field delimiter, a comma in the case of HTTP,
    /// is added by the implementation, and should not be added to the given
    /// value by the caller. Note that, in keeping with the HTTP RFC, HTTP
    /// header field names are case-insensitive.
    /// - Parameter value: the header field value.
    /// - Parameter field: the header field name (case-insensitive).
    public mutating func addValue(_ value: String, forHTTPHeaderField field: String) {
        // Store the field name capitalized to match native Foundation
        let capitalizedFieldName = field.capitalized
        var f: [String: String] = allHTTPHeaderFields ?? [:]
        if let old = existingHeaderField(capitalizedFieldName, inHeaderFields: f) {
            f[old.0] = old.1 + "," + value
        } else {
            f[capitalizedFieldName] = value
        }
        allHTTPHeaderFields = f
    }

    /// This data is sent as the message body of the request, as
    /// in done in an HTTP POST request.
    public var httpBody: Data?

    @available(*, unavailable, message: "httpBodyStream is not yet available in WebFoundation")
    public var httpBodyStream: Any?

    /// `true` if cookies will be sent with and set for this request; otherwise `false`.
    public var httpShouldHandleCookies = true

    /// `true` if the receiver should transmit before the previous response
    /// is received.  `false` if the receiver should wait for the previous response
    /// before transmitting.
    /// Not Supported in WebFoundation
    public let httpShouldUsePipelining = false

    public func hash(into hasher: inout Hasher) {
        hasher.combine(url)
        hasher.combine(mainDocumentURL)
        hasher.combine(httpMethod)
        hasher.combine(httpBody)
        hasher.combine(httpShouldHandleCookies)
    }

    public static func == (lhs: URLRequest, rhs: URLRequest) -> Bool {
        lhs.url == rhs.url
            && lhs.mainDocumentURL == rhs.mainDocumentURL
            && lhs.httpMethod == rhs.httpMethod
            && lhs.cachePolicy == rhs.cachePolicy
            && lhs.httpBody == rhs.httpBody
            && lhs.httpShouldHandleCookies == rhs.httpShouldHandleCookies
    }

    /// Returns an existing key-value pair inside the header fields if it exists.
    private func existingHeaderField(_ key: String, inHeaderFields fields: [String: String]) -> (String, String)? {
        for (k, v) in fields {
            if k.lowercased() == key.lowercased() {
                return (k, v)
            }
        }
        return nil
    }
}

extension URLRequest: CustomStringConvertible, CustomDebugStringConvertible, CustomReflectable {
    public var description: String {
        if let u = url {
            return u.description
        } else {
            return "url: nil"
        }
    }

    public var debugDescription: String {
        description
    }

    public var customMirror: Mirror {
        var c: [(label: String?, value: Any)] = []
        c.append((label: "url", value: url as Any))
        c.append((label: "cachePolicy", value: cachePolicy.rawValue))
        c.append((label: "timeoutInterval", value: timeoutInterval))
        c.append((label: "mainDocumentURL", value: mainDocumentURL as Any))
        c.append((label: "networkServiceType", value: networkServiceType))
        c.append((label: "allowsCellularAccess", value: allowsCellularAccess))
        c.append((label: "httpMethod", value: httpMethod as Any))
        c.append((label: "allHTTPHeaderFields", value: allHTTPHeaderFields as Any))
        c.append((label: "httpBody", value: httpBody as Any))
        c.append((label: "httpShouldHandleCookies", value: httpShouldHandleCookies))
        c.append((label: "httpShouldUsePipelining", value: httpShouldUsePipelining))
        return Mirror(self, children: c, displayStyle: .struct)
    }
}

public extension URLRequest {
    /// A cache policy
    ///
    /// The `URLRequest.CachePolicy` `enum` defines constants that
    /// can be used to specify the type of interactions that take place with
    /// the caching system when the URL loading system processes a request.
    /// Specifically, these constants cover interactions that have to do
    /// with whether already-existing cache data is returned to satisfy a
    /// URL load request.
    enum CachePolicy: UInt {
        /// Specifies that the caching logic defined in the protocol
        /// implementation, if any, is used for a particular URL load request. This
        /// is the default policy for URL load requests.
        case useProtocolCachePolicy
        /// Specifies that the data for the URL load should be loaded from the
        /// origin source. No existing local cache data, regardless of its freshness
        /// or validity, should be used to satisfy a URL load request.
        case reloadIgnoringLocalCacheData
        /// Specifies that not only should the local cache data be ignored, but that
        /// proxies and other intermediates should be instructed to disregard their
        /// caches so far as the protocol allows.  Unimplemented.
        case reloadIgnoringLocalAndRemoteCacheData // Unimplemented
        /// Older name for `NSURLRequestReloadIgnoringLocalCacheData`.
        public static var reloadIgnoringCacheData: CachePolicy { .reloadIgnoringLocalCacheData }
        /// Specifies that the existing cache data should be used to satisfy a URL
        /// load request, regardless of its age or expiration date. However, if
        /// there is no existing data in the cache corresponding to a URL load
        /// request, the URL is loaded from the origin source.
        case returnCacheDataElseLoad
        /// Specifies that the existing cache data should be used to satisfy a URL
        /// load request, regardless of its age or expiration date. However, if
        /// there is no existing data in the cache corresponding to a URL load
        /// request, no attempt is made to load the URL from the origin source, and
        /// the load is considered to have failed. This constant specifies a
        /// behavior that is similar to an "offline" mode.
        case returnCacheDataDontLoad
        /// Specifies that the existing cache data may be used provided the origin
        /// source confirms its validity, otherwise the URL is loaded from the
        /// origin source.
        /// - Note: Unimplemented.
        case reloadRevalidatingCacheData // Unimplemented
    }

    enum NetworkServiceType: UInt {
        /// Standard internet traffic
        case `default`
        /// Voice over IP control traffic
        case voip
        /// Video traffic
        case video
        /// Background traffic
        case background
        /// Voice data
        case voice
        /// Call Signaling
        case networkServiceTypeCallSignaling
    }
}
