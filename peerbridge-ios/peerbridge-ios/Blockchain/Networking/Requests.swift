import Foundation

public struct FilterTransactionsRequest: Codable {
    let publicKey: PEMString
}

public struct TransactionRequest: Codable {
    let sender: String
    let receiver: String
    let data: Data
    
    func send(completion: @escaping (Result<Transaction, Error>) -> Void) {
        var jsonData: Data
        do {
            jsonData = try ISO8601Encoder().encode(self)
        } catch let error {
            completion(.failure(error))
            return
        }
        
        let url = URL(string: "\(Endpoints.main)/blockchain/transactions/new")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let data = data else { return }
            
            do {
                let transaction = try ISO8601Decoder().decode(Transaction.self, from: data)
                completion(.success(transaction))
            } catch let error {
                completion(.failure(error))
                return
            }
        }
        task.resume()
    }
}
