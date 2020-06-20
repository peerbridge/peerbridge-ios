import Foundation

public struct Message: Codable, Equatable, Hashable {
    let nonce: Data
    let date: Date
    let content: String
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.nonce == rhs.nonce
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(nonce)
    }
}
