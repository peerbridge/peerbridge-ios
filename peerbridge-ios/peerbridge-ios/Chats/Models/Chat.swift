import Foundation


struct Chat: Codable, Hashable, Equatable {
    let partner: String
    let lastTransaction: Transaction
    
    init(partner: String, lastTransaction: Transaction) {
        self.partner = partner
        self.lastTransaction = lastTransaction
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(partner)
        hasher.combine(lastTransaction.timestamp)
    }
    
    static func == (lhs: Chat, rhs: Chat) -> Bool {
        return lhs.partner == rhs.partner &&
            lhs.lastTransaction.timestamp == rhs.lastTransaction.timestamp
    }
}
