
import Foundation


class PersistenceEnvironment: ObservableObject {
    @Published var transactions: TransactionRepository
    
    init(transactions: TransactionRepository) {
        self.transactions = transactions
    }
}
