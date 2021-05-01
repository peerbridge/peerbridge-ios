import SwiftUI
import Firebase


fileprivate extension UIApplication {
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil, from: nil, for: nil
        )
    }
}


struct MessagesView: View {
    @EnvironmentObject var persistence: PersistenceEnvironment
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    let chat: Chat
    
    private let publisher = NotificationCenter.default.publisher(for: .newRemoteMessage)
    
    @State private var partnerToken: NotificationToken? = nil
    @State private var ownToken: NotificationToken? = nil
    
    @State private var content: String = ""
    @State private var transactions: [Transaction] = []

    @State private var dataToSend: MessageData?

    private struct MessageData: Identifiable {
        let id = UUID()
        let data: Data
    }
    
    private func sendTokenMessage() {
        UIApplication.shared.endEditing()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        guard let token = Messaging.messaging().fcmToken else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        let message = TokenMessage(token: token)
        guard let data = try? JSONEncoder().encode(message) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        withAnimation {
            dataToSend = .init(data: data)
        }
    }
    
    private func sendContentMessage() {
        UIApplication.shared.endEditing()
        guard content != "" else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        let message = ContentMessage(content: content)
        guard let data = try? JSONEncoder().encode(message) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        withAnimation {
            dataToSend = .init(data: data)
        }
    }
    
    func refreshLocally() {
        guard
            let transactions = try? persistence.transactions
                .getTransactions(withPartner: chat.partnerPublicKey)
        else { return }
        self.transactions = transactions
        
        // Load the push notification tokens
        for transaction in transactions {
            guard ownToken == nil || partnerToken == nil else { break }
            
            guard
                let data = transaction.data,
                let decrypted = try? auth.keyPair.decrypt(
                    data: data, partner: transaction.sender == auth.keyPair.publicKey ?
                        transaction.receiver : transaction.sender
                ),
                let tokenMessage = MessageDecoder().decode(from: decrypted) as? TokenMessage
            else { continue }
            
            if transaction.sender == chat.partnerPublicKey {
                partnerToken = tokenMessage.token
            } else {
                ownToken = tokenMessage.token
            }
        }
    }
    
    func refreshFromRemote() {
        TransactionEndpoint.getAccountTransactions(
            ownPublicKey: auth.keyPair.publicKey
        ) { result in
            switch result {
            case .failure(let error):
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("Update Transactions failed: \(error)")
            case .success(let response):
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                guard let txns = response.transactions else { return }
                persistence.transactions.update(transactions: txns)
                refreshLocally()
            }
        }
    }
    
    var contentField: some View {
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
            Button(action: sendContentMessage) {
                Image(systemName: "paperplane.fill")
                    .renderingMode(.template)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(LinearGradient(
                gradient: Styles.blueGradient,
                startPoint: .topLeading,
                endPoint: .topTrailing
            ))
            .cornerRadius(24)
            .padding(.trailing)
            .padding(.vertical)
        }
    }
    
    var sendTokenNotification: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text("To receive push notifications, you need to share your push notification token.").font(.caption)
                Button(action: sendTokenMessage) {
                    Image(systemName: "paperplane.fill")
                        .renderingMode(.template)
                    Text("Share Token")
                }
                .padding(8)
                .background(LinearGradient(
                    gradient: Styles.blueGradient,
                    startPoint: .topLeading,
                    endPoint: .topTrailing
                ))
                .cornerRadius(12)
                .foregroundColor(.white)
            }
            .padding(4)
        } label: {
            HStack {
                Text("You are not receiving push notifications.")
            }
            .padding(4)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 12, x: 0, y: 4
        )
    }
    
    var noPartnerTokenNotification: some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your partner needs to share his push notification token to get push notifications.")
                    .font(.caption)
            }
            .padding(4)
        } label: {
            HStack {
                Text("Your partner is not receiving push notifications.")
            }
            .padding(4)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 12, x: 0, y: 4
        )
    }

    private var url: URL {
        URL(string: "\(Endpoints.main)/dashboard/account?id=\(chat.partnerPublicKey)")!
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                MessageListView(transactions: $transactions)
                if ownToken == nil {
                    sendTokenNotification
                        .padding(.horizontal)
                        .padding(.top)
                }
                if partnerToken == nil {
                    noPartnerTokenNotification
                        .padding(.horizontal)
                        .padding(.top)
                }
                contentField
            }
            if let d = dataToSend {
                BlurView(style: .light).frame(maxWidth: .infinity, maxHeight: .infinity)
                TransactionCreationView(data: d.data, receiver: chat.partnerPublicKey) { transaction in
                    dataToSend = nil
                    guard let transaction = transaction else { return }
                    content = ""
                    try? persistence.transactions.insert(object: transaction)
                    refreshLocally()
                    // Send a notification if the partner's token is known
                    if let partnerToken = partnerToken {
                        NotificationRequest(
                            to: partnerToken,
                            notification: .newMessage,
                            data: nil
                        ).send { error in
                            if let error = error {
                                print("Notification request send failed with error: \(error)")
                            }
                        }
                    }
                }
            }
        }
        .navigationBarItems(
            trailing: Link(destination: url) {
                HStack {
                    Text(chat.shortHex)
                    IdentificationView(key: chat.partnerPublicKey)
                        .frame(width: 32, height: 32)
                }
            }
        )
        .navigationBarTitle("Messages", displayMode: .inline)
        .onReceive(publisher, perform: { _ in
            refreshFromRemote()
        })
        .onAppear(perform: refreshLocally)
    }
}
