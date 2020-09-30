import Foundation
import LocalAuthentication
import SwiftUI
import SwiftyRSA


class AuthenticationEnvironment: ObservableObject {
    let keyPair: RSAKeyPair
    
    init(keyPair: RSAKeyPair) {
        self.keyPair = keyPair
    }
}


struct AuthenticationView: View {
    @State var error: String? = nil
    @State var auth: AuthenticationEnvironment? = nil
        
    func loadKeypair() {
        do {
            let keyPair = try Authenticator.loadKeyPair()
            self.auth = .init(keyPair: keyPair)
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
            let keyPair = try Crypto.createRandomAsymmetricKeyPair()
            try Authenticator.register(newKeyPair: keyPair)
            self.auth = .init(keyPair: keyPair)
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
                
                Button(action: self.loadKeypair) {
                    Text("Authenticate").padding()
                }
                
                if let error = self.error {
                    Text(error)
                        .font(.footnote)
                        .padding()
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }.onAppear(perform: loadKeypair)
        }
    }
}


#if DEBUG
extension AuthenticationEnvironment {
    static let debugKeyPair = try! Crypto.createRandomAsymmetricKeyPair()
    
    static let debugEnvironment = AuthenticationEnvironment(
        keyPair: debugKeyPair
    )
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
#endif
