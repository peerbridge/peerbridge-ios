import UIKit
import SwiftUI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    var rootView: some View {
        TabView {
            ContentView()
            .tabItem {Text("Sender") }
            .tag(0)
            BlockchainView()
            .tabItem {Text("Explorer") }
            .tag(1)
            StartChatView()
            .tabItem {Text("Start Chat") }
            .tag(2)
        }
    }

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        let contentView = ContentView()

        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: rootView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}
