
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
    
    var background: some View {
        RoundedRectangle(cornerRadius: 12)
            .foregroundColor(isOwnMessage ? Color.blue : Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
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
            .foregroundColor(isOwnMessage ? Color.white : Color.black)
            .background(background)
            .padding(.horizontal)
            
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
        VStack {
            MessageRowView(
                transaction: .example1
            ).environmentObject(AuthenticationEnvironment.bob)
            MessageRowView(
                transaction: .example1
            ).environmentObject(AuthenticationEnvironment.alice)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.04))
    }
}
#endif
