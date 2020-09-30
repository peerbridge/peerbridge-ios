import SwiftUI
import SwiftyRSA


class ChatEnvironment: ObservableObject {
    @Published var partnerPublicKey: PublicKey
    
    init(partnerPublicKey: PublicKey) {
        self.partnerPublicKey = partnerPublicKey
    }
}


struct ChatsView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    @EnvironmentObject var persistence: PersistenceEnvironment
    
    @State var chat: ChatEnvironment?
    @State var chats: [Chat] = []
    
    func handle(url: URL) {
        guard
            let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
            let params = components.queryItems,
            let taintedPublicKey = params.first(where: { $0.name == "publicKey" })?.value,
            let publicKey = try? PublicKey(pemEncoded: taintedPublicKey)
        else { return }
        chat = ChatEnvironment(partnerPublicKey: publicKey)
    }
    
    func loadChats() {
        guard
            let chats = try? persistence.transactions
                .getChats(ownPublicKey: auth.keyPair.publicKeyString)
        else { return }
        self.chats = chats
    }
    
    var body: some View {
        if let chat = chat {
            MessagesView().environmentObject(chat)
        } else {
            NavigationView {
                List(self.chats, id: \.partner) { chat in
                    Button(action: {
                        guard
                            let publicKey = try? PublicKey(pemEncoded: chat.partner)
                        else { return }
                        self.chat = ChatEnvironment(partnerPublicKey: publicKey)
                    }) {
                        ChatRowView(chat: chat)
                    }
                }
                .navigationBarTitle("Chats")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        NavigationLink(destination: PairingView()) {
                            HStack {
                                Image(systemName: "plus")
                                Text("Start Chat")
                            }
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(action: {print("pressed")}) {
                            HStack {
                                Text("Refresh")
                                Image(systemName: "arrow.clockwise")
                            }
                        }
                    }
                }
            }
            .onOpenURL(perform: self.handle)
            .onAppear(perform: self.loadChats)
        }
    }
}


#if DEBUG
extension ChatEnvironment {
    static let debugEnvironment = ChatEnvironment(
        partnerPublicKey: AuthenticationEnvironment.debugKeyPair.publicKey
    )
}

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
