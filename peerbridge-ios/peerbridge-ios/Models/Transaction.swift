import Foundation

public struct Transaction: Codable {
    let nonce: Data
    let sender: String
    let receiver: String
    let data: Data
    let timestamp: Date
}

extension Transaction: Identifiable {
    public var id: String {
        return nonce.base64EncodedString()
    }
}

public extension Transaction {
    static func loadReceived(
        byPublicKey publicKey: String,
        completion: @escaping ([Transaction]?) -> Void
    ) {
        
        let requestPayload = FilterTransactionsRequest(publicKey: publicKey)
        let url = URL(string: "\(Endpoints.main)/blockchain/transactions/received")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try! ISO8601Encoder().encode(requestPayload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard
                error == nil,
                let data = data
            else {
                completion(nil)
                return
            }
            
            do {
                let transactions = try ISO8601Decoder().decode([Transaction].self, from: data)
                completion(transactions)
            } catch let error {
                print(error)
                completion(nil)
            }
        }
        task.resume()
    }
}
