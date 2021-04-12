import SwiftUI

struct ChatRowView: View {
    let chat: Chat
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var messageDescription: String? = nil
    
    var dateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
    
    func decryptMessage() {
        guard let lastTransaction = chat.lastTransaction else {
            messageDescription = "New Chat"
            return
        }


        guard
            let data = lastTransaction.data
        else {
            if lastTransaction.balance > 0 {
                messageDescription = "Cryptocurrency Transfer"
            } else {
                messageDescription = "Empty Message"
            }
            return
        }

        guard let decryptedData = try? auth.keyPair.decrypt(
            data: data, partner: lastTransaction.sender == auth.keyPair.publicKey ?
                lastTransaction.receiver : lastTransaction.sender
        ) else {
            messageDescription = "Encrypted message"
            return
        }
        
        guard let message = MessageDecoder().decode(from: decryptedData) else {
            messageDescription = "Unknown Message"
            return
        }
        
        messageDescription = message.shortDescription
    }
    
    var body: some View {
        HStack(alignment: .top) {
            IdentificationView(key: chat.partnerPublicKey)
                .frame(width: 64, height: 64)
            VStack(alignment: .leading) {
                HStack {
                    Text(chat.shortHex)
                        .font(.headline)
                        .lineLimit(0)
                    Spacer()
                    if let lastTransaction = chat.lastTransaction {
                        Text(lastTransaction.time, style: .relative)
                            .foregroundColor(Color.black.opacity(0.7))
                    }
                }
                if let description = messageDescription {
                    Text(description)
                        .foregroundColor(Color.black.opacity(0.7))
                        .lineLimit(3)
                }
            }
            .padding(.leading, 4)
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .foregroundColor(.white)
                .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
        .onAppear(perform: decryptMessage)
    }
}
