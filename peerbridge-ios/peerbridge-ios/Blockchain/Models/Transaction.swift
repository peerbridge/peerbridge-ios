import Foundation

public struct Transaction: Codable {
    let nonce: Data
    let sender: String
    let receiver: String
    let data: Data
    let timestamp: Date
}

extension Transaction: Identifiable {
    public var id: String {
        return nonce.base64EncodedString()
    }
}

extension Transaction {    
    static func loadAll(
        byPublicKey publicKey: String,
        completion: @escaping ([Transaction]?) -> Void
    ) {
        let requestPayload = FilterTransactionsRequest(publicKey: publicKey)
        let url = URL(string: "\(Endpoints.main)/blockchain/transactions/filter")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try! ISO8601Encoder().encode(requestPayload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                error == nil,
                let data = data
            else {
                completion(nil)
                return
            }
            
            do {
                let transactions = try ISO8601Decoder().decode([Transaction].self, from: data)
                completion(transactions)
            } catch let error {
                print(error)
                completion(nil)
            }
        }
        task.resume()
    }
    
    public func decryptMessage(withKeyPair keyPair: RSAKeyPair) -> Message? {
        guard
            let keyPairPublicKeyString = try? keyPair.publicKey.pemString(),
            let envelope = try? ISO8601Decoder().decode(Envelope.self, from: data)
        else { return nil }
        
        var encryptedSessionKey: Data
        if keyPairPublicKeyString == sender {
            encryptedSessionKey = envelope.encryptedSessionKey.encryptedBySenderPublicKey
        } else {
            encryptedSessionKey = envelope.encryptedSessionKey.encryptedByReceiverPublicKey
        }
        
        guard
            let decryptedSessionKey = try? Crypto.decrypt(
                data: encryptedSessionKey,
                asymmetricallyWithPrivateKey: keyPair.privateKey
            ),
            let decryptedMessageData = try? Crypto.decrypt(
                data: envelope.encryptedMessage,
                symmetricallyWithKeyData: decryptedSessionKey
            )
        else { return nil }
        
        return try? ISO8601Decoder().decode(Message.self, from: decryptedMessageData)
    }
}
