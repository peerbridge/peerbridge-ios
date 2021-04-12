import Foundation

public struct GetTransactionFeeResponse: Codable {
    let fee: Int?
}

public struct GetAccountBalanceResponse: Codable {
    let balance: Int?
}

public struct GetAccountTransactionsResponse: Codable {
    let transactions: [Transaction]?
}

public struct CreateTransactionResponse: Codable {
    let transaction: Transaction?
}
