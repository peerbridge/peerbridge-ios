import Foundation
import SwiftyRSA

public struct Envelope: Codable {
    let nonce: Data
    let encryptedSessionKey: Data
    let encryptedMessage: Data
    
    public func decryptMessage() -> Message? {
        guard
            let keyPairData = Keychain.load(dataBehindKey: "keyPair"),
            let keyPair = try? ISO8601Decoder().decode(RSAKeyPair.self, from: keyPairData),
            let decryptedSessionKey = try? Encryption.decrypt(
                data: encryptedSessionKey,
                asymmetricallyWithPrivateKey: keyPair.privateKey
            ),
            let decryptedMessageData = try? Encryption.decrypt(
                data: encryptedMessage,
                symmetricallyWithKeyData: decryptedSessionKey
            )
            else { return nil }
        return try? ISO8601Decoder().decode(Message.self, from: decryptedMessageData)
    }
}
