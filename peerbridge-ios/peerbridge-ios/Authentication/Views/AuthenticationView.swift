import Foundation
import LocalAuthentication
import SwiftUI
import SwiftyRSA


struct AuthenticationView: View {
    @State var error: String? = nil
    
    func loadKeypair() {
        do {
            let keyPair = try Authenticator.loadKeyPair()
            print(keyPair)
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
            print(keyPair)
        } catch let error {
            withAnimation {
                self.error = "Please try again. \n \(error.localizedDescription)"
            }
        }
    }
    
    var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(white: 0.3), Color(white: 0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Image("Fingerprint")
                .renderingMode(.template)
                .resizable()
                .colorInvert()
                .colorMultiply(.blue)
                .frame(width: 128, height: 128, alignment: .center)
                .padding(8)
            
            Spacer().frame(height: 48)
            
            if self.error != nil {
                Text("\(self.error!)")
                    .font(.footnote)
                    .padding(32)
                    .multilineTextAlignment(.center)
            }
            
            Spacer().frame(height: 48)
            
            Button(action: self.loadKeypair) {
                Text("Authenticate")
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: Color.black.opacity(0.1), radius: 10)
            }
            
            Spacer()
        }
    }
}

struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
    }
}
