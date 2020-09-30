import Foundation

public struct FilterTransactionsRequest: Codable {
    let publicKey: PEMString
}

public struct TransactionRequest: Codable {
    let sender: String
    let receiver: String
    let data: Data
}
