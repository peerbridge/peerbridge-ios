import Foundation

public struct EncryptedSessionKeyPair: Codable {
    let encryptedBySenderPublicKey: Data
    let encryptedByReceiverPublicKey: Data
}
