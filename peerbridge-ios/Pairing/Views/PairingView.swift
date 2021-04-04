import SwiftUI
import Firebase


struct PairingView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment
    
    @State var url: String? = nil
    
    func loadCode() {
        guard
            url == nil
        else { return }
        url = "peerbridge://pair?publicKey=\(auth.keyPair.publicKey)"
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
