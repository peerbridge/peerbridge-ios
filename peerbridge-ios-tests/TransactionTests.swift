import XCTest
import CryptoKit
@testable import peerbridge_ios

class TransactionTest: XCTestCase {
    let transactions = [
        Transaction(
            index: "1",
            sender: "alice",
            receiver: "bob",
            data: "hi bob, this is alice".data(using: .utf8)!,
            timestamp: Date(timeIntervalSince1970: 0)
        ),
        Transaction(
            index: "2",
            sender: "bob",
            receiver: "alice",
            data: "hi alice, this is bob".data(using: .utf8)!,
            timestamp: Date(timeIntervalSince1970: 1000)
        ),
        Transaction(
            index: "3",
            sender: "bob",
            receiver: "alice",
            data: "thanks for giving me your contact".data(using: .utf8)!,
            timestamp: Date(timeIntervalSince1970: 2000)
        ),
        Transaction(
            index: "4",
            sender: "bob",
            receiver: "bob",
            data: "hi bob, this is bob".data(using: .utf8)!,
            timestamp: Date(timeIntervalSince1970: 3000)
        ),
        Transaction(
            index: "6",
            sender: "bob",
            receiver: "bob",
            data: "2nd note to myself".data(using: .utf8)!,
            timestamp: Date(timeIntervalSince1970: 4500)
        ),
        Transaction(
            index: "5",
            sender: "bob",
            receiver: "bob",
            data: "note to myself".data(using: .utf8)!,
            timestamp: Date(timeIntervalSince1970: 4000)
        ),
    ]
    
    func testRepository() throws {
        let repo = try TransactionRepository(location: .inMemory)
        for transaction in transactions {
            try repo.run { table in try table.insert(transaction) }
        }
        let indices = transactions.map { $0.index }
        for transaction in try repo.all() {
            XCTAssertTrue(indices.contains(transaction.index))
        }
        
        let lastTimestamp = try repo.getLastTimestamp()
        XCTAssertEqual(lastTimestamp, Date(timeIntervalSince1970: 4500))
    }
}
