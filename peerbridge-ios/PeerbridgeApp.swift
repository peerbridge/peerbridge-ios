import SwiftUI
import SwiftyRSA


@main
struct PeerbridgeApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @State var persistence: PersistenceEnvironment? = nil
    @State var error: String? = nil
    
    func loadPersistence() {
        do {
            let transactions = try TransactionRepository()
            self.persistence = PersistenceEnvironment(transactions: transactions)
        } catch let error {
            self.error = "There was an error: \(error)"
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let persistence = persistence {
                AuthenticationView().environmentObject(persistence)
            } else {
                if let error = error {
                    VStack {
                        Text(error)
                        Button(action: loadPersistence) {
                            Text("Try again")
                        }
                    }
                } else {
                    VStack {
                        Text("Loading...")
                        ProgressView()
                    }.onAppear(perform: loadPersistence)
                }
            }
        }
    }
}