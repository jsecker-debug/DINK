import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    var onDeviceToken: ((Data) -> Void)?

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        onDeviceToken?(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("[APNs] Failed to register: \(error.localizedDescription)")
    }
}
