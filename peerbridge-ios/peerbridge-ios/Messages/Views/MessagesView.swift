import SwiftUI
import SwiftyRSA


fileprivate extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct MessagesView: View {
    let selectedPartner: PublicKey?
    
    @EnvironmentObject var persistence: PersistenceEnvironment
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: String = ""
    @State var transactions: [Transaction] = []
    
    func sendMessage() {
        UIApplication.shared.endEditing()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let sessionKey = Crypto.createRandomSymmetricKey()
        
        guard
            let selectedPartner = selectedPartner,
            let messageData = message.data(using: .utf8),
            let partnerPublicKeyString = try? selectedPartner.pemString(),
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
                asymmetricallyWithPublicKey: selectedPartner
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
                message = ""
                loadTransactions()
            } catch let error {
                print("The database was not able to save the transaction: \(error)")
            }
        }
        task.resume()
    }
    
    func loadTransactions() {
        guard
            let partnerPublicKeyString = try? selectedPartner?.pemString(),
            let transactions = try? persistence.transactions
                .getTransactions(withPartner: partnerPublicKeyString)
        else { return }
        self.transactions = transactions
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack {
                    ForEach(transactions, id: \.index) { transaction in
                        MessageRowView(transaction: transaction)
                    }
                }
            }
            .padding(.horizontal)
            HStack {
                TextField("Your Message", text: $message, onCommit: {
                    UIApplication.shared.endEditing()
                })
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.05))
                .cornerRadius(24)
                .padding(.leading)
                .padding(.vertical, 12)
                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .renderingMode(.template)
                        .foregroundColor(.white)
                }
                .padding(12)
                .background(Color.blue)
                .cornerRadius(24)
                .padding(.trailing)
                .padding(.vertical)
            }
        }
        .navigationTitle("Messages")
        .onAppear(perform: loadTransactions)
    }
}


#if DEBUG
struct MessagesView_Previews: PreviewProvider {    
    static var previews: some View {
        MessagesView(selectedPartner: .alicePublicKey)
        .environmentObject(AuthenticationEnvironment.alice)
        .environmentObject(PersistenceEnvironment.debug)
    }
}
#endif
