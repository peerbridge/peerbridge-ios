
import SwiftUI

struct MessageRowView: View {
    let transaction: Transaction
    
    var isOwnMessage: Bool {
        return transaction.sender == auth.keyPair.publicKeyString
    }
    
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var message: String = "Loading..."
    
    func decryptMessage() {
        if let decryptedMessage = try? transaction
            .decrypt(withKeyPair: auth.keyPair) {
            self.message = decryptedMessage
        } else {
            self.message = "Message could not be decrypted."
        }
    }
    
    var body: some View {
        HStack {
            if isOwnMessage {
                Spacer()
            }
            VStack(alignment: isOwnMessage ? .trailing : .leading) {
                Text(self.transaction.timestamp, style: .relative)
                    .font(.footnote)
                    .padding(.bottom, 2)
                Text(self.message)
                    .lineLimit(nil)
            }
            .padding(8)
            .background(isOwnMessage ? Color.blue.opacity(0.25) : Color.gray.opacity(0.25))
            .cornerRadius(12)
            if !isOwnMessage {
                Spacer()
            }
        }
        .onAppear(perform: self.decryptMessage)
    }
}

struct MessageRowView_Previews: PreviewProvider {
    static var previews: some View {
        MessageRowView(
            transaction: Transaction(
                index: "0",
                sender: "alice",
                receiver: "bob",
                data: "".data(using: .utf8)!,
                timestamp: Date(timeIntervalSinceNow: -10000)
            )
        ).environmentObject(
            AuthenticationEnvironment.debugEnvironment
        )
    }
}
