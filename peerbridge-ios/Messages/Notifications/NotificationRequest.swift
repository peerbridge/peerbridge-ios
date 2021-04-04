
import Foundation


struct NotificationRequest: Codable {
    struct Notification: Codable {
        let title: String
        let body: String
        
        static let newMessage = Notification(
            title: "You have a new message!",
            body: "Open the PeerBridge App to read further."
        )
    }
    
    let to: NotificationToken
    let notification: Notification
    let data: Data?
    
    enum FileError: Swift.Error {
        case configurationNotFound
        case erroneousConfiguration
    }
    
    static func getServerKey() throws -> String {
        guard
            let path = Bundle.main.path(
                forResource: "GoogleService-Info",
                ofType: "plist"
            )
        else { throw FileError.configurationNotFound }
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        guard
            let config = try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any],
            let serverKey = config["SERVER_KEY"] as? String
        else { throw FileError.erroneousConfiguration }
        return serverKey
    }
    
    func send(completion: @escaping (Error?) -> Void) {
        var serverKey: String
        var jsonData: Data
        do {
            serverKey = try NotificationRequest.getServerKey()
            jsonData = try JSONEncoder().encode(self)
        } catch let error {
            completion(error)
            return
        }
        let url = URL(string: "https://fcm.googleapis.com/fcm/send")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil, let response = response as? HTTPURLResponse else {
                completion(error)
                return
            }
            print("Notification send to \(to.prefix(6))... succeeded. Status: \(response.statusCode)")
            completion(nil)
        }
        task.resume()
    }
}
