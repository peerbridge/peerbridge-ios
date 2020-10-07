import SwiftUI

struct ChatRowView: View {
    let chat: Chat
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: Message? = nil
    
    var dateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }

    func decryptMessage() {
        if let decryptedMessage = try? chat.lastTransaction
            .decrypt(withKeyPair: auth.keyPair) {
            self.message = decryptedMessage
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            IdentificationView(key: chat.partner)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                HStack {
                    Text(chat.partner.infix ?? "...")
                        .font(.headline)
                        .lineLimit(0)
                    Spacer()
                    Text(chat.lastTransaction.timestamp, formatter: self.dateFormatter)
                        .foregroundColor(Color.black.opacity(0.7))
                }
                if let message = message {
                    Text(message.content)
                        .foregroundColor(Color.black.opacity(0.7))
                        .lineLimit(2)
                } else {
                    Text("Encrypted Message")
                        .foregroundColor(Color.black.opacity(0.7))
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .onAppear(perform: self.decryptMessage)
        .padding()
    }
}


#if DEBUG
struct ChatRowView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChatRowView(chat: Chat(
                partner: .bobPublicKeyString,
                lastTransaction: .example1
            )).environmentObject(AuthenticationEnvironment.alice)
            
            ChatRowView(chat: Chat(
                partner: .alicePublicKeyString,
                lastTransaction: .example1
            )).environmentObject(AuthenticationEnvironment.alice)
        }
    }
}
#endif
