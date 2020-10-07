import SwiftUI
import SwiftyRSA


struct ChatsView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    @EnvironmentObject var persistence: PersistenceEnvironment
    
    let publisher = NotificationCenter.default.publisher(for: .newRemoteMessage)
    
    @State var partnerToken: NotificationToken? = nil
    @State var selectedPartner: PublicKey?
    @State var shouldShowMessages = false
    @State var chats: [Chat] = []
    
    func handleURL(url: URL) {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let params = components.queryItems,
            let taintedToken = params.first(where: { $0.name == "token" })?.value,
            let taintedPublicKey = params.first(where: { $0.name == "publicKey" })?.value
        else { return }
        
        do {
            self.selectedPartner = try PublicKey(pemEncoded: taintedPublicKey)
            self.partnerToken = taintedToken
            self.shouldShowMessages = true
        } catch let error {
            print("Error during url handling: \(error)")
        }
    }
    
    func loadChats() {
        guard
            let chats = try? persistence.transactions.getChats(auth: auth)
        else { return }
        self.chats = chats
    }
    
    func fetchTransactions() {
        TransactionEndpoint.fetch(auth: auth) { result in
            switch result {
            case .failure(let error):
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                print("Update Transactions failed: \(error)")
            case .success(let transactions):
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                persistence.transactions.update(transactions: transactions)
                loadChats()
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination: MessagesView(
                        selectedPartner: selectedPartner,
                        partnerToken: partnerToken
                    ),
                    isActive: $shouldShowMessages,
                    label: { EmptyView() }
                )

                List(chats, id: \.partner) { chat in
                    Button {
                        guard
                            let publicKey = try? PublicKey(pemEncoded: chat.partner)
                        else { return }
                        selectedPartner = publicKey
                        shouldShowMessages = true
                    } label: {
                        ChatRowView(chat: chat)
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitle("Chats")
            .navigationBarItems(
                leading: Button(action: fetchTransactions) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
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


#if DEBUG
struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView()
            .environmentObject(AuthenticationEnvironment.alice)
            .environmentObject(PersistenceEnvironment.debug)
    }
}
#endif
