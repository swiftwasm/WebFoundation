import Foundation
import JavaScriptEventLoop
import JavaScriptKit
import WebFoundation
import XCTest

class DownloadTests: XCTestCase {
	// Async tests aren't supported in SwiftWasm 5.6 and earlier.
	#if (os(WASI) && swift(>=5.7)) || canImport(Darwin)
		func testAsyncDownload() async throws {
			let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
			let (data, response) = try await URLSession.shared.data(from: url)
			let posts = try JSONDecoder().decode([Post].self, from: data)
			XCTAssertFalse(posts.isEmpty)
			XCTAssertFalse(posts.first!.title.isEmpty)
		}
	#endif
}

struct Post: Decodable {
	let id: Int
	let title: String
	let body: String
	let userId: Int
}

struct NewPost: Encodable {
	let title: String
	let body: String
	let userId: Int
}
