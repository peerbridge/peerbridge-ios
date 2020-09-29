import SwiftUI

struct ChatsView: View {
    @State var chats: [Chat]
    
    var body: some View {
        List(self.chats, id: \.partner) { chat in
            ChatRowView(chat: chat)
        }
    }
}

struct ChatsView_Previews: PreviewProvider {
    static var previews: some View {
        ChatsView(chats: (0...100).map { (i: Int) -> Chat in
            return Chat(
                partner: "partner \(i)",
                lastMessage: Message(
                    nonce: "123".data(using: .utf8)!,
                    date: Date().addingTimeInterval(-100000 * Double(i)),
                    content: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
                )
            )
        })
    }
}
