
import SwiftUI
import SwiftyRSA

struct ChatView: View {
    @Binding var messages: [Message]
    @Binding var receiverPublicKeyString: String?
    @State var remoteUrl: String = Endpoints.main
    @State var message: String = "Incroyable"
    
    var body: some View {
        ScrollView {
            ForEach(self.messages, id: \.nonce) { message in
                VStack {
                    Text("\(message.nonce)")
                        .lineLimit(1)
                    Text("\(message.date, formatter: RelativeDateTimeFormatter())")
                    Text("\(message.content)")
                }
                .padding(12)
                .background(Color.gray)
                .cornerRadius(16)
            }
            
            VStack {
                Text("Message")
                .padding(.top, 32)
                TextField("Remote", text: self.$message)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .foregroundColor(Color.black)
                Button(action: {
                    let sessionKey = Encryption.createRandomSymmetricKey()
                    
                    let message = Message(
                        nonce: Encryption.createRandomNonce(),
                        date: Date(),
                        content: self.message
                    )
                    let encryptedMessage = try! Encryption.encrypt(
                        data: try! ISO8601Encoder().encode(message),
                        symmetricallyWithKeyData: sessionKey
                    )!
                    let receiverPublicKey = try! PublicKey(pemEncoded: self.receiverPublicKeyString!)
                    var senderPublicKeyString: String
                    if let keyPairData = Keychain.load(dataBehindKey: "keyPair") {
                        let keyPair = try! JSONDecoder().decode(RSAKeyPair.self, from: keyPairData)
                        senderPublicKeyString = try! keyPair.publicKey.pemString()
                    } else {
                        let keyPair = try! Encryption.createRandomAsymmetricKeyPair()
                        try! Keychain.save(try! JSONEncoder().encode(keyPair), forKey: "keyPair")
                        senderPublicKeyString = try! keyPair.publicKey.pemString()
                    }
                    let senderPublicKey = try! PublicKey(pemEncoded: senderPublicKeyString)
                    let encryptedSessionKey = EncryptedSessionKey(
                        encryptedBySenderPublicKey: try! Encryption.encrypt(
                            data: sessionKey,
                            asymmetricallyWithPublicKey: senderPublicKey
                        ),
                        encryptedByReceiverPublicKey: try! Encryption.encrypt(
                            data: sessionKey,
                            asymmetricallyWithPublicKey: receiverPublicKey
                        )
                    )
                    let envelope = Envelope(
                        nonce: Encryption.createRandomNonce(),
                        encryptedSessionKey: encryptedSessionKey,
                        encryptedMessage: encryptedMessage
                    )
                    let transaction = Transaction(
                        nonce: Encryption.createRandomNonce(),
                        sender: senderPublicKeyString,
                        receiver: self.receiverPublicKeyString!,
                        data: try! ISO8601Encoder().encode(envelope),
                        timestamp: Date()
                    )
                    
                    let url = URL(string: "\(self.remoteUrl)/blockchain/transactions/new")!
                    var request = URLRequest(url: url)
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    request.httpMethod = "POST"
                    request.httpBody = try! ISO8601Encoder().encode(transaction)
                    print(String(data: request.httpBody!, encoding: .utf8))
                    let task = URLSession.shared.dataTask(with: request) { data, response, error in
                        guard error == nil else {
                            print(error!)
                            return
                        }
                        guard let data = data else { return }
                        print("Sent message successfully")
                    }
                    task.resume()
                }) {
                    Text("Send message")
                }
            }
        }
    }
}
