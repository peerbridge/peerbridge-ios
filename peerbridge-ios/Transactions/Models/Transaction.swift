import Foundation
import SQLite
import SQLite3
import secp256k1_implementation


public struct Transaction: Codable, Hashable, Equatable {
    let id: String
    let sender: String
    let receiver: String
    let balance: Int
    let timeUnixNano: Int
    let data: Data?
    let fee: Int

    var signature: String?

    var time: Date {
        Date(timeIntervalSince1970: Double(timeUnixNano / 1_000_000_000))
    }

    mutating func sign(privateKey: String) throws {
        var dataStr = ""
        if let data = data {
            dataStr = String(byteArray: data)
        }

        let signatureInputStr = "id:\(id)|sender:\(sender)|receiver:\(receiver)|balance:\(balance)|timeUnixNano:\(timeUnixNano)|data:\(dataStr)|fee:\(fee)"
        let signatureInput = signatureInputStr.data(using: .utf8)!

        let keyBytes = try privateKey.byteArray()
        let key = try secp256k1.Signing.PrivateKey(rawRepresentation: keyBytes)
        let signature = try key.signature(for: signatureInput)
        let signatureString = String(byteArray: try signature.compactRepresentation())

        self.signature = signatureString
    }
}

public class TransactionEndpoint {
    enum NetworkError: Error {
        case noDataReturned
    }
    
    static func getAccountTransactions(
        ownPublicKey: String,
        completion: @escaping (Swift.Result<GetAccountTransactionsResponse, Error>) -> Void
    ) {
        let urlString = "\(Endpoints.main)/blockchain/accounts/transactions/get?account=\(ownPublicKey)"
        let url = URL(string: urlString)!
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
            builder.column(Expression<String>("id"), primaryKey: true)
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
            do {
                try insert(object: transaction)
            } catch {
                print(error)
            }
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
