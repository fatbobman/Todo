import XCTest
@testable import DB

final class DBTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(DB().text, "Hello, World!")
    }
}
