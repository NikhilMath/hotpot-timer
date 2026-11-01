import UIKit
import UserNotifications

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        // No .foreground option: tapping "Restart" (on the phone or the Watch) restarts
        // in the background without opening the app.
        let restart = UNNotificationAction(
            identifier: TimerEngine.restartActionID,
            title: "Restart",
            options: [],
            icon: UNNotificationActionIcon(systemImageName: "arrow.clockwise")
        )
        let category = UNNotificationCategory(
            identifier: TimerEngine.notificationCategory,
            actions: [restart],
            intentIdentifiers: [],
            options: []
        )
        center.setNotificationCategories([category])
        return true
    }

    /// Round ended while the app is open: show the banner anyway and roll the Live Activity over.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        await TimerEngine.shared.sync()
        return [.banner, .list, .sound]
    }

    /// Notification tapped, or its Restart button pressed.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        if response.actionIdentifier == TimerEngine.restartActionID {
            await TimerEngine.shared.restart()
        } else {
            await TimerEngine.shared.sync()
        }
    }
}
