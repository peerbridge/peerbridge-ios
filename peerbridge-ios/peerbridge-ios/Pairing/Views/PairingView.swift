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
        url = "peerbridge://pair?publicKey=\(encodedPublicKey)"
    }
    
    var body: some View {
        VStack {
            if let url = url {
                QRCodeView(uri: url).padding()
            }
            Text("Show this QR Code to another user to start chatting!")
                .padding()
                .multilineTextAlignment(.center)
            Spacer()
        }
        .navigationTitle("Start Chat")
        .onAppear(perform: generateUrl)
    }
}


#if DEBUG
struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView().environmentObject(AuthenticationEnvironment.alice)
    }
}
#endif
