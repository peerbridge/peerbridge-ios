import Foundation
import SQLite

public typealias Message = String


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
        guard
            let message = String(data: decryptedData, encoding: .utf8)
        else { throw Self.Error.wrongEncoding }
        return message
    }
}

public final class TransactionRepository: Repository, ObservableObject {
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
            .select(distinct: [sender, receiver, timestamp.min, table[*]])
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
