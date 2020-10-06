import SwiftUI
import Firebase


struct PairingView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var url: String? = nil
    
    func loadCode() {
        guard
            let encodedPublicKey = auth.keyPair
                .publicKeyString
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return }
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Messaging could not retrieve token: \(error)")
                return
            }
            guard let token = token else { return }
            url = "peerbridge://pair?token=\(token)&publicKey=\(encodedPublicKey)"
        }
    }
    
    var body: some View {
        VStack {
            if let url = url {
                QRCodeView(uri: url).padding()
            } else {
                ProgressView()
            }
            Text("Show this QR Code to another user to start chatting!")
                .padding()
                .multilineTextAlignment(.center)
            Spacer()
        }
        .navigationTitle("Start Chat")
        .onAppear(perform: loadCode)
    }
}


#if DEBUG
struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView().environmentObject(AuthenticationEnvironment.alice)
    }
}
#endif
