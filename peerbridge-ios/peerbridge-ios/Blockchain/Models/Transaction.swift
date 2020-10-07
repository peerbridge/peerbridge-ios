import Foundation
import SQLite
import SQLite3


public struct Transaction: Codable {
    enum Error: Swift.Error {
        case wrongEncoding
    }
    
    let index: String
    let sender: String
    let receiver: String
    let data: Data
    let timestamp: Date
    
    var description: String {
        return data.base64EncodedString()
    }
    
    func decrypt(withKeyPair keyPair: RSAKeyPair) throws -> Message {
        let decoder = ISO8601Decoder()
        let keyPairPublicKeyString = try keyPair.publicKey.pemString()
        let envelope = try decoder.decode(Envelope.self, from: data)
        let encryptedSessionKey = keyPairPublicKeyString == sender ?
            envelope.encryptedSessionKeyPair.encryptedBySenderPublicKey :
            envelope.encryptedSessionKeyPair.encryptedByReceiverPublicKey
        let decryptedSessionKey = try Crypto.decrypt(
            data: encryptedSessionKey,
            asymmetricallyWithPrivateKey: keyPair.privateKey
        )
        let decryptedData = try Crypto.decrypt(
            data: envelope.encryptedMessage,
            symmetricallyWithKeyData: decryptedSessionKey
        )
        let message = try ISO8601Decoder().decode(Message.self, from: decryptedData)
        return message
    }
}

public class TransactionEndpoint {
    enum NetworkError: Error {
        case noDataReturned
    }
    
    static func fetch(
        auth: AuthenticationEnvironment,
        completion: @escaping (Swift.Result<[Transaction], Error>) -> Void
    ) {
        fetch(ownPublicKey: auth.keyPair.publicKeyString, completion: completion)
    }
    
    static func fetch(
        ownPublicKey: PEMString,
        completion: @escaping (Swift.Result<[Transaction], Error>) -> Void
    ) {
        let requestPayload = FilterTransactionsRequest(publicKey: ownPublicKey)
        let url = URL(string: "\(Endpoints.main)/blockchain/transactions/filter")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        do {
            request.httpBody = try ISO8601Encoder().encode(requestPayload)
        } catch let error {
            completion(.failure(error))
            return
        }
        
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
                let transactions = try ISO8601Decoder()
                    .decode([Transaction].self, from: data)
                completion(.success(transactions))
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
            builder.column(Expression<Data>("data"))
            builder.column(Expression<Date>("timestamp"))
        })
    }
    
    func update(transactions: [Transaction]) {
        for transaction in transactions {
            // TODO: handle errors (excluding duplicate insertion)
            try? insert(object: transaction)
        }
    }
    
    func getLastTimestamp() throws -> Date {
        let timestamp = Expression<Date>("timestamp")
        let mostRecentTransaction = try get { table in table
            .order(timestamp.asc)
        }
        return mostRecentTransaction.timestamp
    }
    
    func getTransactions(withPartner partnerPublicKey: PEMString) throws -> [Transaction] {
        let sender = Expression<String>("sender")
        let receiver = Expression<String>("receiver")
        let timestamp = Expression<Date>("timestamp")
        
        return try fetch { table in table
            .filter(sender == partnerPublicKey || receiver == partnerPublicKey)
            .order(timestamp)
        }
    }
    
    func getChats(auth: AuthenticationEnvironment) throws -> [Chat] {
        return try getChats(ownPublicKey: auth.keyPair.publicKeyString)
    }
    
    func getChats(ownPublicKey: PEMString) throws -> [Chat] {
        let sender = Expression<String>("sender")
        let receiver = Expression<String>("receiver")
        let timestamp = Expression<Date>("timestamp")
        
        let rows: AnySequence<Row> = try fetch { table in table
            .select(distinct: [sender, receiver, timestamp.max, table[*]])
            .order(timestamp.asc)
            .group([sender, receiver])
        }
        let latestUnidirectionalTransactions = try rows
            .map { row in try row.decode() as Transaction }
        // The result of the query may contain two entries
        // for the same chat, with swapped sender/receiver.
        // We only need the most recent chat, and since the
        // query is ordered by the timestamp, we can simply
        // sequentially iterate over the transactions and
        // mark each as the most recent encountered one.
        var chatsByPartner = [String: Chat]()
        for transaction in latestUnidirectionalTransactions {
            let partner = transaction.sender == ownPublicKey ?
                transaction.receiver : transaction.sender
            chatsByPartner[partner] = Chat(partner: partner, lastTransaction: transaction)
        }
        return chatsByPartner.values
            .sorted { $0.lastTransaction.timestamp > $1.lastTransaction.timestamp }
    }
}
