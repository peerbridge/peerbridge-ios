import XCTest
import CryptoKit
import SQLite
@testable import peerbridge_ios

class TransactionTest: XCTestCase {
    let transactions = [
        Transaction(
            nonce: "123",
            sender: "alice",
            receiver: "bob",
            data: "skrrrt".data(using: .utf8)!,
            timestamp: Date()
        ),
        Transaction(
            nonce: "321",
            sender: "alice",
            receiver: "bob",
            data: "yaaarrrnnn".data(using: .utf8)!,
            timestamp: Date()
        ),
    ]
    
    func testRepository() throws {
        let repo = try TransactionRepository(location: .inMemory)
        for transaction in transactions {
            try repo.run { try $0.insert(transaction) }
        }
        let nonces = transactions.map { $0.nonce }
        for row in try repo.all() {
            XCTAssertTrue(nonces.contains(try row.get(Expression<String>("nonce"))))
        }
    }
}
