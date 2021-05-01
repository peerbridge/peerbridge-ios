import SwiftUI


@main
struct PeerbridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// An environment to access persisted objects.
    @StateObject var persistence = PersistenceEnvironment()
    
    var body: some Scene {
        WindowGroup {
            AuthenticationView().environmentObject(persistence)
        }
    }
}
