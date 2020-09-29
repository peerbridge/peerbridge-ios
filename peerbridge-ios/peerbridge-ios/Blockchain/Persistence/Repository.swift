import Foundation
import SQLite

protocol Repository {
    var connection: Connection { get set }
    var table: Table { get set }
}

extension Repository {
    func run(block: (Table) throws -> Insert) throws {
        try connection.run(try block(table))
    }
    
    func run(block: (Table) throws -> Delete) throws {
        try connection.run(try block(table))
    }
    
    func run(block: (Table) throws -> Update) throws {
        try connection.run(try block(table))
    }
    
    func all() throws -> AnySequence<Row> {
        return try connection.prepare(table)
    }
}
