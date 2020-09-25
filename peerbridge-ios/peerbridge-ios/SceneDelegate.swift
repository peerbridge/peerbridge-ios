import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var rootView: some View {
        AuthenticationView()
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: rootView)
            self.window = window
            window.makeKeyAndVisible()
            
            do {
                let puk = try Authenticator.loadPublicKey()
                let prk = try Authenticator.loadPrivateKey(for: puk)
                print(puk, prk)
            } catch let error {
                print(error.localizedDescription)
            }
        }
    }
}
