import SwiftUI
import SwiftyRSA

// This is just an experimental view, therefore we ignore some guidelines for now
// swiftlint:disable all
struct ContentView: View {
    @State var publicKey: String?
    @State var privateKey: String?
    @State var sessionKey: Data?
    @State var remoteUrl: String = Endpoint.main
    @State var message: String = "Incroyable"
    @State var sendMessageResponseString: String?
    @State var decryptedMessagesFromBlockchain = [String]()

    func sendMessage() {
        let encryptedMessage = try! Encryption.encrypt(
            data: message.data(using: .utf8)!,
            symmetricallyWithKeyData: sessionKey!
        )!
        // The message will be send to oneself
        let receiverPublicKey = try! PublicKey(pemEncoded: publicKey!)
        let encryptedSessionKey = try! Encryption.encrypt(
            data: sessionKey!,
            asymmetricallyWithPublicKey: receiverPublicKey
        )
        let message = Message(
            encryptedSessionKey: encryptedSessionKey,
            encryptedMessage: encryptedMessage
        )
        let transaction = Transaction(
            sender: publicKey!,
            receiver: publicKey!,
            data: try! JSONEncoder().encode(message),
            timestamp: Date()
        )
        
        let url = URL(string: "\(remoteUrl)/blockchain/transactions/new")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        request.httpBody = try! encoder.encode(transaction)
        print(request.httpBody?.prettyPrintedJSONString)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print(error)
                return
            }
            guard let data = data else { return }
            self.sendMessageResponseString = String(data: data, encoding: .utf8)
        }
        task.resume()
    }
    
    func filterTransactions() {
        let requestPayload = FilterTransactionsRequest(publicKey: self.publicKey!)
        let url = URL(string: "\(remoteUrl)/blockchain/transactions/filter")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = try! JSONEncoder().encode(requestPayload)
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print(error)
                return
            }
            guard let data = data else { return }
            print(data.prettyPrintedJSONString)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let transactions = try! decoder.decode([Transaction].self, from: data)
            let messages = transactions.map {transaction -> String in
                let message = try! decoder.decode(Message.self, from: transaction.data)
                let privateKey = try! PrivateKey(pemEncoded: self.privateKey!)
                let decryptedSessionKey = try! Encryption.decrypt(data: message.encryptedSessionKey, asymmetricallyWithPrivateKey: privateKey)
                let decryptedMessage = try! Encryption.decrypt(data: message.encryptedMessage, symmetricallyWithKeyData: decryptedSessionKey)
                return String(data: decryptedMessage, encoding: .utf8)!
            }
            self.decryptedMessagesFromBlockchain = messages
        }
        task.resume()
    }
    
    var body: some View {
        VStack {
            Group {
                Text("Blockchain URL")
                TextField("Remote", text: self.$remoteUrl)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                Text("Message")
                TextField("Message", text: self.$message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }
            Button(action: self.sendMessage) {
                Text("Send message to myself")
            }
            Text("Send Message Response: \(self.sendMessageResponseString ?? "n/a")")
                .lineLimit(2)
            Button(action: self.filterTransactions) {
                Text("Load messages from blockchain")
            }
            Spacer()
            List(self.decryptedMessagesFromBlockchain, id: \.self) { message in
                Text(message)
            }
        }
        .padding(32)
        .onAppear {
            if let keyPairData = Keychain.load(dataBehindKey: "keyPair") {
                let keyPair = try! JSONDecoder().decode(RSAKeyPair.self, from: keyPairData)
                self.publicKey = try! keyPair.publicKey.pemString()
                self.privateKey = try! keyPair.privateKey.pemString()
            } else {
                let keyPair = try! Encryption.createRandomAsymmetricKeyPair()
                try! Keychain.save(try! JSONEncoder().encode(keyPair), forKey: "keyPair")
                self.publicKey = try! keyPair.publicKey.pemString()
                self.privateKey = try! keyPair.privateKey.pemString()
            }
            self.sessionKey = Encryption.createRandomSymmetricKey()
            // swiftlint:enable all
        }
    }
}

// swiftlint:disable:next type_name
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
