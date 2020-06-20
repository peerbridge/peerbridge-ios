
import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftyRSA
import CryptoKit

struct StartChatView: View {
    enum SheetType {
        case scanner
        case sendMessage
    }
    
    @State var isPresentingSheet = false
    @State var presentedSheet: SheetType?
    @State var remoteUrl: String = Endpoints.main
    @State var message: String = "Incroyable"
    @State var receiverPublicKeyString: String?
    
    func generateOwnQRCode() -> UIImage {
        var senderPublicKeyString: String
        if let keyPairData = Keychain.load(dataBehindKey: "keyPair") {
            let keyPair = try! JSONDecoder().decode(RSAKeyPair.self, from: keyPairData)
            senderPublicKeyString = try! keyPair.publicKey.pemString()
        } else {
            let keyPair = try! Encryption.createRandomAsymmetricKeyPair()
            try! Keychain.save(try! JSONEncoder().encode(keyPair), forKey: "keyPair")
            senderPublicKeyString = try! keyPair.publicKey.pemString()
        }
        
        let data = Data(senderPublicKeyString.utf8)
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.setValue(data, forKey: "inputMessage")
        let outputImage = filter.outputImage!
        let cgImage = context.createCGImage(outputImage, from: outputImage.extent)!
        return UIImage(cgImage: cgImage)
    }

    var body: some View {
        VStack {
            Image(uiImage: self.generateOwnQRCode())
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
            Button("Scan Code") {
                self.presentedSheet = .scanner
                self.isPresentingSheet = true
            }
            .sheet(isPresented: self.$isPresentingSheet) {
                if self.presentedSheet == .scanner {
                    self.scannerSheet
                } else {
                    self.sendMessageSheet
                }
            }
            Text("Scan a QR code to begin")
        }
    }

    var scannerSheet: some View {
        CodeScannerView(
            codeTypes: [.qr],
            completion: { result in
                if case let .success(code) = result {
                    self.isPresentingSheet = false
                    self.receiverPublicKeyString = code
                    self.presentedSheet = .sendMessage
                    self.isPresentingSheet = true
                }
            }
        )
    }
    
    var sendMessageSheet: some View {
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
                    self.isPresentingSheet = false
                }
                task.resume()
            }) {
                Text("Send message")
            }
        }
    }
}

struct StartChatView_Previews: PreviewProvider {
    static var previews: some View {
        StartChatView()
    }
}
