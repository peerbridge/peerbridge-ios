import SwiftUI

struct ChatRowView: View {
    let chat: Chat
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: Message = "Decrypting message..."

    func decryptMessage() {
        if let decryptedMessage = try? chat.lastTransaction
            .decrypt(withKeyPair: auth.keyPair) {
            self.message = decryptedMessage
        } else {
            self.message = "Message could not be decrypted."
        }
    }
    
    var body: some View {
        HStack(alignment: .top) {
            IdentificationView(key: chat.partner)
                .frame(width: 70, height: 70)
            VStack(alignment: .leading) {
                HStack {
                    Text(chat.partner)
                        .font(.headline)
                        .lineLimit(0)
                    Spacer()
                    Text(chat.lastTransaction.timestamp, style: .relative)
                        .foregroundColor(Color.black.opacity(0.7))
                }
                Text(self.message)
                    .foregroundColor(Color.black.opacity(0.7))
                    .lineLimit(2)
            }
            .padding(.leading)
            Spacer()
        }
        .padding(.vertical)
        .onAppear(perform: self.decryptMessage)
    }
}


#if DEBUG
struct ChatRowView_Previews: PreviewProvider {
    static var previews: some View {
        ChatRowView(chat: Chat(
            partner: .bobPublicKeyString,
            lastTransaction: .example1
        )).environmentObject(AuthenticationEnvironment.alice)
    }
}
#endif
