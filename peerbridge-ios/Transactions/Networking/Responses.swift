import Foundation

public struct GetAccountTransactionsResponse: Codable {
    let transactions: [Transaction]?
}

public struct CreateTransactionResponse: Codable {
    let transaction: Transaction?
}
