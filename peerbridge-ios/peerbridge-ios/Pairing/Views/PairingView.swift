import SwiftUI

struct PairingView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var url: String? = nil
    
    func generateUrl() {
        guard
            let encodedPublicKey = auth.keyPair
                .publicKeyString
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return }
        self.url = "peerbridge://pair?publicKey=\(encodedPublicKey)"
    }
    
    var body: some View {
        VStack {
            Text("Show this QR Code to another user to start chatting!")
                .padding()
                .multilineTextAlignment(.center)
            if let url = url {
                QRCodeView(uri: url).padding()
            }
            Text("peerbridge://your-public-key")
                .font(.footnote)
                .multilineTextAlignment(.center)
        }.onAppear(perform: self.generateUrl)
    }
}

struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView().environmentObject(AuthenticationEnvironment.debugEnvironment)
    }
}
