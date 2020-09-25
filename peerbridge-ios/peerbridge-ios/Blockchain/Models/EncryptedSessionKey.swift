import Foundation

public struct EncryptedSessionKey: Codable {
    let encryptedBySenderPublicKey: Data
    let encryptedByReceiverPublicKey: Data
}
