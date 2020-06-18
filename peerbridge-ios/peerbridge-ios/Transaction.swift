import Foundation

public struct Transaction: Codable {
    let sender: String
    let receiver: String
    let data: Data
    let timestamp: Date
}

extension Transaction: Identifiable {
    public var id: String {
        return "\(timestamp)\(sender)\(receiver)"
    }
}
