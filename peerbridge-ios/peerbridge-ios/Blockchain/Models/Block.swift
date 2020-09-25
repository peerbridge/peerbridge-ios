import Foundation

public struct Block: Codable {
    let index: UInt64
    let timestamp: Date
    let parentHash: [UInt8]
    let transactions: [Transaction]
}

extension Block: Identifiable, Equatable {
    public var id: String {
        return "\(index)"
    }
    
    public static func == (lhs: Block, rhs: Block) -> Bool {
        return lhs.id == rhs.id
    }
}
