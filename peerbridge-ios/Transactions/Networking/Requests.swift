import Foundation

public struct CreateTransactionRequest: Codable {
    let transaction: Transaction
    
    func send(completion: @escaping (Result<CreateTransactionResponse, Error>) -> Void) {
        var jsonData: Data
        do {
            jsonData = try JSONEncoder().encode(self)
        } catch let error {
            completion(.failure(error))
            return
        }
        
        let url = URL(string: "\(Endpoints.main)/blockchain/transaction/create")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard
                let data = data,
                let response = response as? HTTPURLResponse
            else { return }

            print(response.statusCode)
            print(String(data: data, encoding: .utf8))

            do {
                let response = try JSONDecoder().decode(CreateTransactionResponse.self, from: data)
                completion(.success(response))
            } catch let error {
                completion(.failure(error))
                return
            }
        }
        task.resume()
    }
}
