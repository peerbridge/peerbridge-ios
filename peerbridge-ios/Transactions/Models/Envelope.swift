import Foundation

public struct Envelope: Codable {
    let encryptedSessionKeyPair: EncryptedSessionKeyPair
    let encryptedMessage: Data
}
