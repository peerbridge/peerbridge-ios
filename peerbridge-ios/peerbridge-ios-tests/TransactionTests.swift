import XCTest
import CryptoKit
import SQLite
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
        
        let chats = try repo.getChats(ownPublicKey: "bob")
        XCTAssertEqual(chats.count, 2)
        XCTAssertEqual(
            chats.map { $0.partner },
            ["bob", "alice"],
            "The most recent chat should be the first entry!"
        )
    }
    
    struct Example: Codable {
        let date: Date
    }
    
    func testDeserialization() throws {
        print(ISO8601DateFormatter().date(from: "2020-09-30T15:01:10.349854Z"))
    }
}