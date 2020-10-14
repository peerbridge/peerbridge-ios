import XCTest
import CryptoKit
import SQLite
@testable import peerbridge_ios


fileprivate struct Book: Codable, Equatable {
    let title: String
    let author: String
    let published: Date
    let viewers: Int
    
    static let example1 = Book(
        title: "Example 1",
        author: "Author 1",
        published: Date(timeIntervalSince1970: 0),
        viewers: 420
    )
    
    static let example2 = Book(
        title: "Example 2",
        author: "Author 2",
        published: Date(timeIntervalSince1970: 1000),
        viewers: 420
    )
    
    static let example3 = Book(
        title: "Example 3",
        author: "Author 3",
        published: Date(timeIntervalSince1970: 200),
        viewers: 420
    )
    
    static func == (lhs: Book, rhs: Book) -> Bool {
        return lhs.title == rhs.title
    }
}


fileprivate class BookRepository: Repository {
    typealias Object = Book
    
    var connection: Connection
    var table: Table
    
    init() throws {
        connection = try Connection(.temporary)
        table = Table("books")
        
        try connection.run(table.create(ifNotExists: false) { builder in
            builder.column(Expression<String>("title"), primaryKey: true)
            builder.column(Expression<String>("author"))
            builder.column(Expression<Date>("published"))
            builder.column(Expression<Int>("viewers"))
        })
    }
}


class RepositoryTest: XCTestCase {
    func testRepository() throws {
        let repo = try BookRepository()
        let books: [Book] = [.example1, .example2, .example3]
        
        let title = Expression<String>("title")
        do {
            _ = try repo.get { $0.filter(title == "Example 1") }
            XCTFail("The repo should be empty!")
        } catch RepositoryError.objectNotFound {
            // empty repo, as assumed
        } catch let error {
            XCTFail("The repo should not throw this error: \(error)")
        }
        
        for book in books {
            try repo.insert(object: book)
        }
        XCTAssertEqual(books, try repo.all())
        XCTAssertEqual(Book.example1, try repo.get { $0.filter(title == "Example 1") })
    }
}


class RepositoryLoadTest: XCTestCase {
    fileprivate let books = (0...1000).map { (i: Int) -> Book in Book(
        title: "Example \(i)",
        author: "Author \(i)",
        published: Date(timeIntervalSince1970: Double(i)),
        viewers: i
    ) }
    
    func testLoad() throws {
        measure {
            do {
                let repo = try BookRepository()
                for book in books {
                    try repo.insert(object: book)
                }
                let books = try repo.all()
                XCTAssertEqual(self.books, books)
            } catch let error {
                XCTFail("The repo failed with: \(error)")
            }
        }
    }
}
