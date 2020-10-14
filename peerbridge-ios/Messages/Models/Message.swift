
import Foundation


public protocol TransactionMessage: Codable {
    /// Messages must denote a type identifier string to avoid decoding ambiguity
    var typeIdentifier: String { get }
    
    /// Messages must give a short description for the chat view preview
    var shortDescription: String { get }
}


extension TransactionMessage {
    func send(
        keyPair: RSAKeyPair,
        partnerPublicKey: RSAPublicKey,
        completion: @escaping (Result<Transaction, Error>) -> Void
    ) {
        let sessionKey = Crypto.createRandomSymmetricKey()
        
        do {
            let messageData = try ISO8601Encoder().encode(self)
            let encryptedMessage = try Crypto.encrypt(
                data: messageData,
                symmetricallyWithKeyData: sessionKey
            )
            let encryptedBySenderPublicKey = try Crypto.encrypt(
                data: sessionKey,
                asymmetricallyWithPublicKey: keyPair.publicKey.key
            )
            let encryptedByReceiverPublicKey = try Crypto.encrypt(
                data: sessionKey,
                asymmetricallyWithPublicKey: partnerPublicKey.key
            )
            let encryptedSessionKeyPair = EncryptedSessionKeyPair(
                encryptedBySenderPublicKey: encryptedBySenderPublicKey,
                encryptedByReceiverPublicKey: encryptedByReceiverPublicKey
            )
            let envelope = Envelope(
                encryptedSessionKeyPair: encryptedSessionKeyPair,
                encryptedMessage: encryptedMessage
            )
            let transactionData = try ISO8601Encoder().encode(envelope)
            TransactionRequest(
                sender: keyPair.publicKey.pemString,
                receiver: partnerPublicKey.pemString,
                data: transactionData
            ).send(completion: completion)
        } catch let error {
            completion(.failure(error))
            return
        }
    }
}
