
import SwiftUI

struct MessageRowView: View {
    let transaction: Transaction
    
    var isOwnMessage: Bool {
        transaction.sender == auth.keyPair.publicKeyString
    }
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: String = "Encrypted Message"
    
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
                    Text(transaction.timestamp, style: .relative)
                        .font(.caption2)
                    Image(systemName: "lock")
                        .resizable()
                        .frame(width: 8, height: 10)
                }
                .padding(.bottom, 2)
                Text(message)
                    .lineLimit(nil)
                    .padding(.bottom, 2)
            }
            .padding(8)
            .background(isOwnMessage ? Color.blue.opacity(0.6) : Color.blue.opacity(0.25))
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
            transaction: .example1,
            message: "Overridden message for testing and preview purposes"
        ).environmentObject(AuthenticationEnvironment.bob)
    }
}
#endif
