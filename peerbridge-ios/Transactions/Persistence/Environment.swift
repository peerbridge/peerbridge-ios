
import Foundation


class PersistenceEnvironment: ObservableObject {
    @Published var transactions: TransactionRepository

    convenience init() {
        let transactions = try! TransactionRepository()
        self.init(transactions: transactions)
    }
    
    init(transactions: TransactionRepository) {
        self.transactions = transactions
    }
}
