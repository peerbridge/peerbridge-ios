import SwiftUI
import SwiftyRSA
import Firebase


fileprivate extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


struct MessagesView: View {
    @EnvironmentObject var persistence: PersistenceEnvironment
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    let selectedPartner: PublicKey?
    
    let publisher = NotificationCenter.default.publisher(for: .newRemoteMessage)
    
    @State var partnerToken: NotificationToken? = nil
    @State var content: String = ""
    @State var transactions: [Transaction] = []
        
    func sendMessage() {
        // TODO: Refactor this method
        
        UIApplication.shared.endEditing()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let sessionKey = Crypto.createRandomSymmetricKey()
        
        guard
            let selectedPartner = selectedPartner,
            let partnerPublicKeyString = try? selectedPartner.pemString(),
            let partnerToken = partnerToken,
            let ownToken = Messaging.messaging().fcmToken,
            let messageData = try? ISO8601Encoder()
                .encode(Message(content: content, token: ownToken)),
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
        transactionRequest.send { result in
            guard let transaction = try? result.get() else { return }
            try? persistence.transactions.insert(object: transaction)
            
            let notificationRequest = NotificationRequest(
                to: partnerToken,
                notification: .newMessage,
                data: nil
            )
            notificationRequest.send { error in
                if let error = error {
                    print("Notification request send failed with error: \(error)")
                    return
                }
                
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                content = ""
                refreshLocally()
            }
        }
    }
    
    func refreshLocally() {
        guard
            let partnerPublicKeyString = try? selectedPartner?.pemString(),
            let transactions = try? persistence.transactions
                .getTransactions(withPartner: partnerPublicKeyString)
        else { return }
        self.transactions = transactions
        
        // If there are transactions with this partner,
        // get the most recent push notification token for him
        for transaction in transactions.reversed() {
            guard
                transaction.sender == partnerPublicKeyString,
                let message = try? transaction.decrypt(withKeyPair: auth.keyPair)
            else { continue }
            partnerToken = message.token
            return
        }
    }
    
    func refreshFromRemote() {
        TransactionEndpoint.fetch(auth: auth) { result in
            switch result {
            case .failure(let error):
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("Update Transactions failed: \(error)")
            case .success(let transactions):
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                persistence.transactions.update(transactions: transactions)
                refreshLocally()
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                LazyVStack {
                    ForEach(transactions, id: \.index) { transaction in
                        MessageRowView(transaction: transaction)
                    }
                }
            }
            .padding(.vertical)
            if partnerToken != nil {
                HStack {
                    TextField("Your Message", text: $content, onCommit: {
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
        }
        .navigationTitle("Messages")
        .onReceive(publisher, perform: { _ in
            refreshFromRemote()
        })
        .onAppear(perform: refreshLocally)
    }
}


#if DEBUG
struct MessagesView_Previews: PreviewProvider {    
    static var previews: some View {
        MessagesView(selectedPartner: .alicePublicKey, partnerToken: nil)
        .environmentObject(AuthenticationEnvironment.alice)
        .environmentObject(PersistenceEnvironment.debug)
    }
}
#endif
