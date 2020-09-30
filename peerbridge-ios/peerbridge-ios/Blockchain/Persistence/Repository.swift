import Foundation
import SQLite

enum RepositoryError: Swift.Error {
    case objectNotFound
}

protocol Repository {
    associatedtype Object: Codable
    
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

    func insert(object: Object) throws {
        try run { table in try table.insert(object) }
    }

    func update(object: Object) throws {
        try run { table in try table.update(object) }
    }
    
    func fetch(query: QueryType) throws -> AnySequence<Row> {
        return try connection.prepare(query)
    }
    
    func fetch(block: (Table) throws -> QueryType) throws -> AnySequence<Row> {
        return try fetch(query: try block(table))
    }
    
    func fetch(block: (Table) throws -> QueryType) throws -> [Object] {
        return try fetch(block: block).map { row in try row.decode() }
    }
    
    func get(block: (Table) throws -> QueryType) throws -> Object {
        guard
            let row = try connection.pluck(try block(table))
        else { throw RepositoryError.objectNotFound }
        return try row.decode()
    }
    
    func all() throws -> [Object] {
        return try fetch { table in table }
    }
}
