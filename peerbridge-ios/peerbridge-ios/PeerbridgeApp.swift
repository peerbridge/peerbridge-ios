import SwiftUI
import SwiftyRSA
import Firebase


class PersistenceEnvironment: ObservableObject {
    @Published var transactions: TransactionRepository
    
    init(transactions: TransactionRepository) {
        self.transactions = transactions
    }
}


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


class AppDelegate: NSObject, UIApplicationDelegate {
    private func handleNotificationUpdate(withUserInfo userInfo: [AnyHashable: Any]) {
        let content = UNMutableNotificationContent()
        content.title = "New message"
        content.body = "Open the Peerbridge App to view a new message"
        content.sound = .default
        content.categoryIdentifier = "message"
        content.userInfo = userInfo

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "message", content: content, trigger: trigger
        )
        UNUserNotificationCenter.current().add(request) { error in
            guard let error = error else { return }
            print("Error adding notification: \(error)")
        }
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        notificationCenter.requestAuthorization(options: authOptions) { _, _ in }
        
        UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        
        print(Messaging.messaging().fcmToken ?? "No FCM Token")
        
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print(error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any]) {
        handleNotificationUpdate(withUserInfo: userInfo)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable : Any],
        fetchCompletionHandler completionHandler:
            @escaping (UIBackgroundFetchResult) -> Void
    ) {
        handleNotificationUpdate(withUserInfo: userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.badge, .banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        handleNotificationUpdate(withUserInfo: userInfo)
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String
    ) {
        print("Received the FCM token: \(fcmToken)")
    }
}
