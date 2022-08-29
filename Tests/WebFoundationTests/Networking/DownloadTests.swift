import Foundation
import XCTest
import WebFoundation
import JavaScriptKit
import JavaScriptEventLoop

class DownloadTests: XCTestCase {
	func testAsyncDownload() async throws {
		let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
		let (data, response) = try await URLSession.shared.data(from: url)
		let posts = try JSONDecoder().decode([Post].self, from: data)
		XCTAssertFalse(posts.isEmpty)
		XCTAssertFalse(posts.first!.title.isEmpty)
	}
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