import Foundation

public struct Block: Codable {
    let index: UInt64
    let timestamp: Date
    let parentHash: [UInt8]
    let transactions: [Transaction]

    private enum CodingKeys: String, CodingKey {
        case index
        case timestamp
        case parentHash
        case transactions
    }

    public init(index: UInt64, timestamp: Date, parentHash: [UInt8], transactions: [Transaction]) {
        self.index = index
        self.timestamp = timestamp
        self.parentHash = parentHash
        self.transactions = transactions
    }

    // TODO: Remove this custom date decoder
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.index = try container.decode(UInt64.self, forKey: .index)
        self.parentHash = try container.decode([UInt8].self, forKey: .parentHash)
        self.transactions = try container.decode([Transaction].self, forKey: .transactions)
        let dateString = try container.decode(String.self, forKey: .timestamp)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = .withFractionalSeconds
        self.timestamp = dateFormatter.date(from: dateString)!
    }
}

extension Block: Identifiable, Equatable {
    public var id: String {
        return "\(index)"
    }
    
    public static func == (lhs: Block, rhs: Block) -> Bool {
        return lhs.id == rhs.id
    }
}
