
import SwiftUI

struct MessageRowView: View {
    let transaction: Transaction
    
    var isOwnMessage: Bool {
        transaction.sender == auth.keyPair.publicKeyString
    }
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: String = "Loading..."
    
    func decryptMessage() {
        if let decryptedMessage = try? transaction
            .decrypt(withKeyPair: auth.keyPair) {
            message = decryptedMessage
        } else {
            message = "Message could not be decrypted."
        }
    }
    
    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer()
            }
            
            VStack(alignment: isOwnMessage ? .trailing : .leading) {
                Text(transaction.timestamp, style: .relative)
                    .font(.footnote)
                    .padding(.bottom, 2)
                Text(message)
                    .lineLimit(nil)
            }
            .padding(8)
            .background(isOwnMessage ? Color.blue.opacity(0.25) : Color.gray.opacity(0.25))
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
        MessageRowView(transaction: .example1)
            .environmentObject(AuthenticationEnvironment.alice)
    }
}
#endif
