import Foundation

public struct Envelope: Codable {
    let nonce: Data
    let encryptedSessionKey: EncryptedSessionKey
    let encryptedMessage: Data
}
