import Foundation
import JavaScriptKit

extension JSTypedArray where Element == UInt8 {
	func toData() -> Data {
		withUnsafeBytes { buffer in
			Data(buffer: buffer)
		}
	}
	
	convenience init(_ data: Data) {
		let elements = [UInt8](data)
		self.init(elements)
	}
}

extension Data {
	func blob() -> JSObject {
		let typedArray = JSTypedArray(self)
		let blobConstructor = JSObject.global.Blob.function!
		let blob = blobConstructor.new(typedArray)
		return blob
	}
}
