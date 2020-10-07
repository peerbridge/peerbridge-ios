
import SwiftUI

struct MessageRowView: View {
    let transaction: Transaction
    
    var isOwnMessage: Bool {
        transaction.sender == auth.keyPair.publicKeyString
    }
    
    var dateFormatter: RelativeDateTimeFormatter {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter
    }
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: Message? = nil
    
    func decryptMessage() {
        if let decryptedMessage = try? transaction
            .decrypt(withKeyPair: auth.keyPair) {
            message = decryptedMessage
        }
    }
    
    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer()
            }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading) {
                HStack {
                    Text(transaction.timestamp, formatter: dateFormatter)
                        .font(.caption2)
                    Image(systemName: "lock")
                        .resizable()
                        .frame(width: 8, height: 10)
                }
                .padding(.bottom, 2)
                if let message = message {
                    Text(message.content)
                        .lineLimit(nil)
                        .padding(.bottom, 2)
                } else {
                    Text("Encrypted Message")
                        .lineLimit(nil)
                        .padding(.bottom, 2)
                }
            }
            .padding(8)
            .background(isOwnMessage ? Color.green.opacity(0.6) : Color.green.opacity(0.25))
            .cornerRadius(12)
            
            if !isOwnMessage {
                Spacer()
            }
        }
        .onAppear(perform: decryptMessage)
    }
}


#if DEBUG
struct MessageRowView_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowView(
            transaction: .example1
        ).environmentObject(AuthenticationEnvironment.bob)
    }
}
#endif
