
import Foundation


public protocol TransactionMessage: Codable {
    /// Messages must denote a type identifier string to avoid decoding ambiguity
    var typeIdentifier: String { get }
    
    /// Messages must give a short description for the chat view preview
    var shortDescription: String { get }
}


extension TransactionMessage {
    func send(
        keyPair: Authenticator.KeyPair,
        partnerPublicKey: String,
        completion: @escaping (Result<CreateTransactionResponse, Error>) -> Void
    ) {
        do {
            let messageData = try JSONEncoder().encode(self)

            var keyData = Data(count: 32)
            let result = keyData.withUnsafeMutableBytes {
                (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
                SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
            }

            if result != errSecSuccess {
                fatalError("Random SHA256 could not be generated!")
            }

            let transaction = Transaction(
                id: String(byteArray: keyData),
                sender: keyPair.publicKey,
                receiver: partnerPublicKey,
                balance: 0, // TODO: Support money transfer
                timeUnixNano: Int64(Date().timeIntervalSince1970 * 1_000_000),
                data: messageData, // TODO: encrypt message
                fee: 0, // TODO: use recommended fee from server
                signature: nil // TODO: sign
            )

            CreateTransactionRequest(transaction: transaction).send(completion: completion)
        } catch let error {
            completion(.failure(error))
            return
        }
    }
}
