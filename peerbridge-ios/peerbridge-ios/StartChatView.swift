
import SwiftUI
import CoreImage.CIFilterBuiltins
import SwiftyRSA

struct StartChatView: View {
    enum SheetType {
        case scanner
        case sendMessage
    }
    
    @State var isPresentingSheet = false
    @State var presentedSheet: SheetType?
    @State var remoteUrl: String = Endpoint.main
    @State var message: String = "Incroyable"
    @State var receiverPublicKey: String?
    
    func generateOwnQRCode() -> UIImage {
        var publicKey: String
        if let keyPairData = Keychain.load(dataBehindKey: "keyPair") {
            let keyPair = try! JSONDecoder().decode(RSAKeyPair.self, from: keyPairData)
            publicKey = try! keyPair.publicKey.pemString()
        } else {
            let keyPair = try! Encryption.createRandomAsymmetricKeyPair()
            try! Keychain.save(try! JSONEncoder().encode(keyPair), forKey: "keyPair")
            publicKey = try! keyPair.publicKey.pemString()
        }
        
        let data = Data(publicKey.utf8)
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
                    self.receiverPublicKey = code
                    self.presentedSheet = .sendMessage
                    self.isPresentingSheet = true
                }
            }
        )
    }
    
    var sendMessageSheet: some View {
        VStack {
            Text("Blockchain URL")
            .padding(.top, 32)
            TextField("Remote", text: self.$remoteUrl)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .foregroundColor(Color.black)
            Text("Message")
            .padding(.top, 32)
            TextField("Remote", text: self.$message)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .foregroundColor(Color.black)
            Button(action: {
                guard let publicKey = self.receiverPublicKey else {return}
                let sessionKey = Encryption.createRandomSymmetricKey()
                let encryptedMessage = try! Encryption.encrypt(
                    data: self.message.data(using: .utf8)!,
                    symmetricallyWithKeyData: sessionKey
                )!
                let receiverPublicKey = try! PublicKey(pemEncoded: publicKey)
                let encryptedSessionKey = try! Encryption.encrypt(
                    data: sessionKey,
                    asymmetricallyWithPublicKey: receiverPublicKey
                )
                let message = Message(
                    encryptedSessionKey: encryptedSessionKey,
                    encryptedMessage: encryptedMessage
                )
                let transaction = Transaction(
                    sender: publicKey,
                    receiver: publicKey,
                    data: try! JSONEncoder().encode(message),
                    timestamp: Date()
                )
                
                let url = URL(string: "\(self.remoteUrl)/blockchain/transactions/new")!
                var request = URLRequest(url: url)
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpMethod = "POST"
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                request.httpBody = try! encoder.encode(transaction)
                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    guard error == nil else {
                        print(error)
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
