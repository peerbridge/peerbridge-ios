import SwiftUI
import SwiftyRSA


struct MessagesView: View {
    @EnvironmentObject var persistence: PersistenceEnvironment
    @EnvironmentObject var auth: AuthenticationEnvironment
    @EnvironmentObject var chat: ChatEnvironment
    
    @State var message: String = ""
    @State var transactions: [Transaction] = []
    
    func sendMessage() {
        let sessionKey = Crypto.createRandomSymmetricKey()
        
        guard
            let messageData = message.data(using: .utf8),
            let partnerPublicKeyString = try? chat.partnerPublicKey.pemString(),
            let encryptedMessage = try? Crypto.encrypt(
                data: messageData,
                symmetricallyWithKeyData: sessionKey
            ),
            let encryptedBySenderPublicKey = try? Crypto.encrypt(
                data: sessionKey,
                asymmetricallyWithPublicKey: auth.keyPair.publicKey
            ),
            let encryptedByReceiverPublicKey = try? Crypto.encrypt(
                data: sessionKey,
                asymmetricallyWithPublicKey: chat.partnerPublicKey
            )
        else { return }
        
        let encryptedSessionKeyPair = EncryptedSessionKeyPair(
            encryptedBySenderPublicKey: encryptedBySenderPublicKey,
            encryptedByReceiverPublicKey: encryptedByReceiverPublicKey
        )
        let envelope = Envelope(
            encryptedSessionKeyPair: encryptedSessionKeyPair,
            encryptedMessage: encryptedMessage
        )
        
        guard
            let transactionData = try? ISO8601Encoder().encode(envelope)
        else { return }
        
        let transactionRequest = TransactionRequest(
            sender: auth.keyPair.publicKeyString,
            receiver: partnerPublicKeyString,
            data: transactionData
        )
        
        guard
            let jsonData = try? ISO8601Encoder().encode(transactionRequest)
        else { return }
        
        let url = URL(string: "\(Endpoints.main)/blockchain/transactions/new")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print(error!)
                return
            }
            guard let data = data else { return }
            
            do {
                let transaction = try ISO8601Decoder().decode(Transaction.self, from: data)
                try persistence.transactions.insert(object: transaction)
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                self.message = ""
                self.loadTransactions()
            } catch let error {
                print("The database was not able to save the transaction: \(error)")
            }
        }
        task.resume()
    }
    
    func loadTransactions() {
        guard
            let partnerPublicKeyString = try? chat.partnerPublicKey
                .pemString(),
            let transactions = try? persistence.transactions
                .getTransactions(withPartner: partnerPublicKeyString)
        else { return }
        self.transactions = transactions
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List(self.transactions, id: \.index) { transaction in
                    MessageRowView(transaction: transaction)
                }.listStyle(PlainListStyle())
                Spacer()
                HStack {
                    TextField("Your Message", text: self.$message)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.leading)
                    Button(action: self.sendMessage) {
                        Text("Send")
                    }.padding()
                }
            }.toolbar() {
                ToolbarItem(placement: .destructiveAction) {
                    HStack {
                        IdentificationView(
                            key: (try? chat.partnerPublicKey.pemString()) ?? ""
                        )
                        .frame(width: 30, height: 30)
                        .padding(.leading, 4)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Text("Messages").font(.title)
                }
            }
        }.onAppear(perform: self.loadTransactions)
    }
}

struct MessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MessagesView(
            transactions: [
                Transaction(
                    index: "1",
                    sender: "alice",
                    receiver: "bob",
                    data: "test".data(using: .utf8)!,
                    timestamp: Date(timeIntervalSinceNow: -1000)
                )
            ]
        )
        .environmentObject(AuthenticationEnvironment.debugEnvironment)
        .environmentObject(ChatEnvironment.debugEnvironment)
    }
}
