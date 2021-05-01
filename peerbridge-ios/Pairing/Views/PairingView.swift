import SwiftUI
import Firebase


private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        .init(
            activityItems: activityItems,
            applicationActivities: nil
        )
    }

    func updateUIViewController(
        _ uiViewController: UIActivityViewController,
        context: Context
    ) { /* Protocol requirement */ }
}


struct PairingView: View {
    @EnvironmentObject var auth: AuthenticationEnvironment

    @State var initialBrightness: CGFloat? = nil
    @State var url: String? = nil
    @State var showsShareSheet = false
    
    func loadCode() {
        guard
            url == nil
        else { return }
        url = "peerbridge://pair?publicKey=\(auth.keyPair.publicKey)"
        print("Our public key: \(auth.keyPair.publicKey)")
    }

    var publicKeyField: some View {
        HStack(spacing: 24) {
            Text(auth.keyPair.publicKey)
                .font(.headline)
            Button { showsShareSheet = true } label: {
                Image(systemName: "square.and.arrow.up")
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(10)
        .padding(2)
        .background(LinearGradient(
            gradient: Styles.blueGradient,
            startPoint: .topLeading,
            endPoint: .topTrailing
        ))
        .cornerRadius(12)
    }
    
    var body: some View {
        VStack {
            if let url = url {
                Text("Your public key")
                QRCodeView(uri: url).padding()
                Text("Show this QR Code to another user to start chatting!")
                    .padding()
                    .multilineTextAlignment(.center)
                Spacer()
                publicKeyField
                    .padding()
            } else {
                ProgressView()
            }
        }
        .sheet(isPresented: $showsShareSheet, content: {
            ShareSheet(activityItems: [auth.keyPair.publicKey])
        })
        .navigationTitle("Start Chat")
        .onAppear(perform: loadCode)
        .onAppear(perform: {
            // Make the screen brighter for scanning
            initialBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        })
        .onDisappear(perform: {
            // Dim the screen back to the initial value
            guard let initialBrightness = initialBrightness else { return }
            UIScreen.main.brightness = initialBrightness
        })
    }
}

#if DEBUG
struct PairingView_Previews: PreviewProvider {
    static var previews: some View {
        PairingView()
            .environmentObject(AuthenticationEnvironment.random())
    }
}
#endif
