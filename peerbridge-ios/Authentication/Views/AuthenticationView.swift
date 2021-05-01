import Foundation
import LocalAuthentication
import SwiftUI


class AuthenticationEnvironment: ObservableObject {
    let keyPair: Authenticator.KeyPair
    
    init(keyPair: Authenticator.KeyPair) {
        self.keyPair = keyPair
    }
}


#if DEBUG
extension AuthenticationEnvironment {
    /// Generate a random new auth environment for debugging.
    static func random() -> AuthenticationEnvironment {
        .init(keyPair: Authenticator.newKeyPair())
    }
}
#endif


struct AuthenticationView: View {
    @State var error: String? = nil
    @State var auth: AuthenticationEnvironment? = nil
        
    func loadKeypair() {
        do {
            let keyPair = try Authenticator.loadKeyPair()
            auth = .init(keyPair: keyPair)
        } catch Authenticator.Error.noKeyPair {
            newKeypair()
        } catch let error {
            withAnimation {
                self.error = "Please try again. \n \(error.localizedDescription)"
            }
        }
    }
    
    func newKeypair() {
        do {
            let keyPair = Authenticator.newKeyPair()
            try Authenticator.register(newKeyPair: keyPair)
            auth = .init(keyPair: keyPair)
        } catch let error {
            withAnimation {
                self.error = "Please try again. \n \(error.localizedDescription)"
            }
        }
    }
    
    var body: some View {
        if let auth = auth {
            ChatsView().environmentObject(auth)
        } else {
            VStack {
                Spacer()
                
                Image("Fingerprint")
                    .renderingMode(.template)
                    .resizable()
                    .colorInvert()
                    .colorMultiply(.black)
                    .frame(width: 128, height: 128, alignment: .center)
                    .padding()
                
                Button(action: loadKeypair) {
                    Text("Authenticate").padding()
                }
                
                if let error = error {
                    Text(error)
                        .font(.footnote)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }.onAppear(perform: loadKeypair) // TODO
        }
    }
}


#if DEBUG
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
#endif
