import SwiftUI


struct ChatsView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    @EnvironmentObject var persistence: PersistenceEnvironment
    
    let publisher = NotificationCenter.default.publisher(for: .newRemoteMessage)
        
    @State var chats: [Chat] = []

    @State var isFetchingTransactions = false
    @AppStorage("last-txn-fetch") var lastTransactionFetch = Date()
    
    func handleURL(url: URL) {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let params = components.queryItems,
            let taintedPublicKey = params.first(where: { $0.name == "publicKey" })?.value
        else { return }

        chats.append(.init(partnerPublicKey: taintedPublicKey, lastTransaction: nil))
    }
    
    func loadChats() {
        // TODO: Group transactions by conversation partner
        guard let transactions = try? persistence.transactions.all() else { return }
        var txnsByPartner = [String: Transaction]()

        for t in transactions {
            let partner = auth.keyPair.publicKey == t.receiver ? t.sender : t.receiver
            if let existingT = txnsByPartner[partner] {
                if existingT.timeUnixNano < t.timeUnixNano {
                    txnsByPartner[partner] = t
                }
            } else {
                txnsByPartner[partner] = t
            }
        }

        var newChats = [Chat]()
        for (p, t) in txnsByPartner {
            newChats.append(.init(partnerPublicKey: p, lastTransaction: t))
        }
        chats = newChats
    }
    
    func fetchTransactions() {
        isFetchingTransactions = true
        TransactionEndpoint.getAccountTransactions(
            ownPublicKey: auth.keyPair.publicKey
        ) { result in
            isFetchingTransactions = false
            switch result {
            case .failure(let error):
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("Update Transactions failed: \(error)")
            case .success(let response):
                guard let txns = response.transactions else { return }
                persistence.transactions.update(transactions: txns)
                lastTransactionFetch = Date()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                loadChats()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Text("Last updated \(lastTransactionFetch, style: .relative) ago")
                    .foregroundColor(.gray)
                    .padding(.horizontal)
                ScrollView {
                    LazyVStack {
                        ForEach(chats, id: \.self) { chat in
                            NavigationLink(destination: MessagesView(chat: chat)) {
                                ChatRowView(chat: chat)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle("Chats")
            .navigationBarItems(
                leading: Button(action: fetchTransactions) {
                    HStack {
                        if isFetchingTransactions {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                        Text("Update")
                    }
                },
                trailing: NavigationLink(destination: PairingView()) {
                    HStack {
                        Text("Start Chat")
                        Image(systemName: "plus")
                    }
                }
            )
        }
        .onOpenURL(perform: handleURL)
        .onAppear(perform: loadChats)
        .onReceive(publisher, perform: { _ in fetchTransactions() })
    }
}
