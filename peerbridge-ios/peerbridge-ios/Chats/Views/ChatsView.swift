import SwiftUI
import SwiftyRSA


struct ChatsView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    @EnvironmentObject var persistence: PersistenceEnvironment
    
    @State var selectedPartner: PublicKey?
    @State var shouldShowMessages = false
    @State var chats: [Chat] = []
    
    func handleURL(url: URL) {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let params = components.queryItems,
            let taintedPublicKey = params.first(where: { $0.name == "publicKey" })?.value,
            let publicKey = try? PublicKey(pemEncoded: taintedPublicKey)
        else { return }
        self.selectedPartner = publicKey
        self.shouldShowMessages = true
    }
    
    func loadChats() {
        guard
            let chats = try? persistence.transactions.getChats(auth: auth)
        else { return }
        self.chats = chats
    }
    
    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(
                    destination: MessagesView(selectedPartner: selectedPartner),
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
                .navigationBarTitle("Chats")
                .navigationBarItems(trailing:
                    NavigationLink(destination: PairingView()) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Start Chat")
                        }
                    }
                )
            }
        }
        .onOpenURL(perform: handleURL)
        .onAppear(perform: loadChats)
    }
}


#if DEBUG
struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView(
            chats: (0...10).map { (i: Int) -> Chat in
                return Chat(
                    partner: "Partner \(i)",
                    lastTransaction: Transaction(
                        index: UUID().uuidString,
                        sender: "alice",
                        receiver: "bob",
                        data: "Lorem Ipsum".data(using: .utf8)!,
                        timestamp: Date().addingTimeInterval(-10000)
                    )
                )
            }
        )
        .environmentObject(AuthenticationEnvironment.debugEnvironment)
    }
}
#endif
