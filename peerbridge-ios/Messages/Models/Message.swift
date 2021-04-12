
import Foundation
import CryptoKit

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

            let data = try JSONEncoder().encode(self)
            let encryptedData = try keyPair.encrypt(data: data, partner: partnerPublicKey)

            var transaction = Transaction(
                id: idData.hexString,
                sender: keyPair.publicKey,
                receiver: partnerPublicKey,
                balance: 0, // TODO: Support money transfer
                timeUnixNano: Int(Date().timeIntervalSince1970 * 1_000_000_000),
                data: encryptedData,
                fee: 0, // TODO: use recommended fee from server
                signature: nil
            )

            try keyPair.sign(t: &transaction)

            CreateTransactionRequest(transaction: transaction).send(completion: completion)
        } catch let error {
            completion(.failure(error))
            return
        }
    }
}
