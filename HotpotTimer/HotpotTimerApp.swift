import SwiftData
import SwiftUI

@main
struct HotpotTimerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: SessionRecord.self)
    }
}
