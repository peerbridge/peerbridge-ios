import Foundation
import SQLite

public struct Transaction: Codable {
    let nonce: String
    let sender: String
    let receiver: String
    let data: Data
    let timestamp: Date    
}

extension Transaction: Identifiable {
    public var id: String {
        return nonce
    }
}

public final class TransactionRepository: Repository {
    enum Error: Swift.Error {
        case noDirectory
    }
    
    var connection: Connection
    var table: Table
    
    init(location: Connection.Location? = nil) throws {
        if let location = location {
            // use the custom specified location
            self.connection = try Connection(location)
        } else {
            // use a default disk-backed database location
            guard
                let path = NSSearchPathForDirectoriesInDomains(
                    .documentDirectory, .userDomainMask, true
                ).first
            else { throw Self.Error.noDirectory }
            self.connection = try Connection("\(path)/db.sqlite3")
        }
        
        self.table = Table("transactions")
        
        try connection.run(table.create(ifNotExists: true) { builder in
            builder.column(Expression<Data>("nonce"), primaryKey: true)
            builder.column(Expression<String>("sender"))
            builder.column(Expression<String>("receiver"))
            builder.column(Expression<Data>("data"))
            builder.column(Expression<Date>("timestamp"))
        })
    }
}
