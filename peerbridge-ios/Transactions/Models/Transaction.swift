import Foundation
import SQLite
import SQLite3


public struct Transaction: Codable, Hashable, Equatable {
    let id: String
    let sender: String
    let receiver: String
    let balance: UInt64
    let timeUnixNano: Int64
    let data: Data?
    let fee: UInt64

    var signature: String?
}

public class TransactionEndpoint {
    enum NetworkError: Error {
        case noDataReturned
    }
    
    static func getAccountTransactions(
        ownPublicKey: String,
        completion: @escaping (Swift.Result<GetAccountTransactionsResponse, Error>) -> Void
    ) {
        let url = URL(string: "\(Endpoints.main)/blockchain/accounts/transactions/get?account=\(ownPublicKey)")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else {
                completion(.failure(NetworkError.noDataReturned))
                return
            }
            do {
                let response = try JSONDecoder()
                    .decode(GetAccountTransactionsResponse.self, from: data)
                completion(.success(response))
            } catch let error {
                completion(.failure(error))
            }
        }
        task.resume()
    }
}

public class TransactionRepository: Repository, ObservableObject {
    typealias Object = Transaction
    
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
            builder.column(Expression<String>("index"), primaryKey: true)
            builder.column(Expression<String>("sender"))
            builder.column(Expression<String>("receiver"))
            builder.column(Expression<Int>("balance"))
            builder.column(Expression<Int>("timeUnixNano"))
            builder.column(Expression<Data>("data"))
            builder.column(Expression<Int>("fee"))
            builder.column(Expression<String>("signature"))
        })
    }
    
    func update(transactions: [Transaction]) {
        for transaction in transactions {
            // TODO: handle errors (excluding duplicate insertion)
            try? insert(object: transaction)
        }
    }
    
    func getTransactions(withPartner publicKey: String) throws -> [Transaction] {
        let sender = Expression<String>("sender")
        let receiver = Expression<String>("receiver")
        let timeUnixNano = Expression<Int>("timeUnixNano")
        
        return try fetch { table in table
            .filter(sender == publicKey || receiver == publicKey)
            .order(timeUnixNano)
        }
    }
}
