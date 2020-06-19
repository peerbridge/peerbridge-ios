import Foundation

public struct Message: Codable, Equatable {
    let nonce: Data
    let date: Date
    let content: String
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.nonce == rhs.nonce
    }
}
