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
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
            [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()

        Messaging.messaging().delegate = self
        
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        UNUserNotificationCenter.current().delegate = self
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in }
        )

        application.registerForRemoteNotifications()
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any]
    ) {
        // If you are receiving a notification message while your app is in the background,
        // this callback will not be fired till the user taps on the notification launching the application.

        print("Received remote notification with userInfo: \(userInfo)")
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler:
            @escaping (UIBackgroundFetchResult) -> Void
    ) {
        self.application(application, didReceiveRemoteNotification: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        print("Will present notification with userInfo: \(userInfo)")
        completionHandler([[.banner, .sound]])
    }
}

extension AppDelegate : MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")

        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
    }
}
