
import Foundation
import secp256k1_implementation


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
            var idData = Data(count: 32)
            let result = idData.withUnsafeMutableBytes {
                (mutableBytes: UnsafeMutablePointer<UInt8>) -> Int32 in
                SecRandomCopyBytes(kSecRandomDefault, 32, mutableBytes)
            }

            if result != errSecSuccess {
                fatalError("Random SHA256 could not be generated!")
            }

            var transaction = Transaction(
                id: String(byteArray: idData),
                sender: keyPair.publicKey,
                receiver: partnerPublicKey,
                balance: 0, // TODO: Support money transfer
                timeUnixNano: Int(Date().timeIntervalSince1970 * 1_000_000),
                data: try JSONEncoder().encode(self), // TODO: encrypt message
                fee: 0, // TODO: use recommended fee from server
                signature: nil
            )

            try transaction.sign(privateKey: keyPair.privateKey)

            CreateTransactionRequest(transaction: transaction).send(completion: completion)
        } catch let error {
            completion(.failure(error))
            return
        }
    }
}
