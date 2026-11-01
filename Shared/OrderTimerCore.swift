import ActivityKit
import Foundation
import UserNotifications
import WidgetKit

/// Timer actions that must work from the app *and* the widget extension.
///
/// iOS doesn't always run the Restart intent inside the app (StandBy widget buttons, and
/// Live Activity buttons on some iOS 17 releases, run it in the extension), so everything
/// Restart needs lives here and only touches App Group state.
enum OrderTimerCore {
    static let roundLength: TimeInterval = 10 * 60
    static let notificationCategory = "HOTPOT_ROUND"
    static let restartActionID = "HOTPOT_RESTART"
    /// iOS keeps at most 64 pending local notifications per app. 48 rounds = 8 hours of hotpot,
    /// and the queue is topped up every time the app opens.
    static let roundsToSchedule = 48

    /// Countdown back to 10:00 from now; all pending notifications are replaced.
    static func restart(at now: Date = .now) async {
        SharedStore.defaults.set(now, forKey: SharedStore.Keys.anchor)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        await scheduleNotifications(anchor: now)
        await updateLiveActivities(anchor: now)
        reloadWidgets()
    }

    static func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.orderTimerWidgetKind)
    }

    static func scheduleNotifications(anchor: Date) async {
        let center = UNUserNotificationCenter.current()
        await removePendingRounds()

        let now = Date.now
        let firstRoundEnding = SharedStore.round(anchor: anchor, at: now, length: roundLength).number

        for round in firstRoundEnding..<(firstRoundEnding + roundsToSchedule) {
            // A restart/stop happened while we were awaiting; that call owns the schedule now.
            guard SharedStore.anchor == anchor else { return }

            let fireDate = anchor.addingTimeInterval(Double(round) * roundLength)
            let content = UNMutableNotificationContent()
            content.title = "Order time! 📲"
            content.body = "10 minutes up — order more on the tablet! 🥩"
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = notificationCategory
            content.threadIdentifier = "hotpot"

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: fireDate.timeIntervalSince(now),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: "hotpot.round.\(round)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func removePendingRounds() async {
        let center = UNUserNotificationCenter.current()
        let ids = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("hotpot.round.") }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    static func liveActivityContent(anchor: Date, at date: Date = .now) -> ActivityContent<HotpotActivityAttributes.ContentState> {
        let round = SharedStore.round(anchor: anchor, at: date, length: roundLength)
        let state = HotpotActivityAttributes.ContentState(
            roundStart: round.start,
            roundEnd: round.end,
            round: round.number,
            totalPlates: SharedStore.totalPlates
        )
        // Marked stale when the round ends, so the widget can say "order now" if the
        // app isn't around to roll it over.
        return ActivityContent(state: state, staleDate: round.end)
    }

    /// Updates running Live Activities only; starting one has to happen in the app.
    /// Returns false if there was none to update.
    @discardableResult
    static func updateLiveActivities(anchor: Date) async -> Bool {
        let activities = Activity<HotpotActivityAttributes>.activities
        guard let current = activities.first else { return false }
        await current.update(liveActivityContent(anchor: anchor))
        for extra in activities.dropFirst() {
            await extra.end(nil, dismissalPolicy: .immediate)
        }
        return true
    }

    static func endLiveActivities() async {
        for activity in Activity<HotpotActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
