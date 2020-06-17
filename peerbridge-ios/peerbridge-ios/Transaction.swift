import Foundation

public struct Transaction: Codable {
    let sender: String
    let receiver: String
    let data: Data
}
