import Foundation

public struct GetTransactionFeeRequest: Codable {
    func send(completion: @escaping (Result<GetTransactionFeeResponse, Error>) -> Void) {
        let url = URL(string: "\(Endpoints.main)/blockchain/fees/get")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

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

            do {
                let response = try JSONDecoder().decode(GetTransactionFeeResponse.self, from: data)
                completion(.success(response))
            } catch let error {
                completion(.failure(error))
                return
            }
        }
        task.resume()
    }
}

public struct GetAccountBalanceRequest: Codable {
    let account: String

    func send(completion: @escaping (Result<GetAccountBalanceResponse, Error>) -> Void) {
        let url = URL(string: "\(Endpoints.main)/blockchain/accounts/balance/get?account=\(account)")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"

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

            do {
                let response = try JSONDecoder().decode(GetAccountBalanceResponse.self, from: data)
                completion(.success(response))
            } catch let error {
                completion(.failure(error))
                return
            }
        }
        task.resume()
    }
}

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
