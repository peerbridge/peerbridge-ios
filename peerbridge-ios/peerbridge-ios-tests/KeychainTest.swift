import XCTest
@testable import peerbridge_ios

class KeychainTest: XCTestCase {
    func testKeychain() throws {
        XCTAssertNil(Keychain.load(stringBehindKey: "password"))
        try Keychain.save("123456", forKey: "password")
        XCTAssertEqual(Keychain.load(stringBehindKey: "password"), "123456")
        try Keychain.save("123456", forKey: "password")
        XCTAssertEqual(Keychain.load(stringBehindKey: "password"), "123456")
        try Keychain.save("654321", forKey: "password")
        XCTAssertEqual(Keychain.load(stringBehindKey: "password"), "654321")
        try Keychain.delete(dataForKey: "password")
        XCTAssertNil(Keychain.load(stringBehindKey: "password"))
        try Keychain.delete(dataForKey: "password")
        XCTAssertNil(Keychain.load(stringBehindKey: "password"))
    }
}
