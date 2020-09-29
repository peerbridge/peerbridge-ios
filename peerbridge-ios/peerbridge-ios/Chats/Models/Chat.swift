import Foundation


struct Chat: Codable {
    let partner: String
    let lastMessage: Message
}
