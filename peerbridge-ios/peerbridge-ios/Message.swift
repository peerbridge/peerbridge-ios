import Foundation

struct Message: Codable {
    let encryptedSessionKey: Data
    let encryptedMessage: Data
}
