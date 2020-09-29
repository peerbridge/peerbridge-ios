import SwiftUI

struct ChatRowView: View {
    let chat: Chat
    
    var body: some View {
        HStack(alignment: .top) {
            IdentificationView(key: chat.partner)
                .frame(width: 70, height: 70)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("\(chat.partner)")
                        .font(.headline)
                        .lineLimit(0)
                    Spacer()
                    Text("\(chat.lastMessage.date, formatter: RelativeDateTimeFormatter())")
                        .foregroundColor(Color.black.opacity(0.7))
                }
                Text("\(chat.lastMessage.content)")
                    .foregroundColor(Color.black.opacity(0.7))
                    .lineLimit(2)
            }
            .padding(.leading, 8)
            Spacer()
        }
        .padding(.vertical, 16)
    }
}

struct ChatRowView_Previews: PreviewProvider {
    static var previews: some View {
        ChatRowView(chat: Chat(
            partner: "expect this to be a very long public key",
            lastMessage: Message(
                nonce: "123".data(using: .utf8)!,
                date: Date().addingTimeInterval(-10000),
                content: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet."
            )
        ))
    }
}
