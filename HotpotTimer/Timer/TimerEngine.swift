import ActivityKit
import Foundation
import Observation
import UserNotifications
import WidgetKit

/// Owns the repeating 10-minute timer.
///
/// The timer is just an anchor date: round N ends at `anchor + N × 10 min`. Everything else
/// (the on-screen countdown, pending notifications, the Live Activity) is derived from it,
/// so nothing depends on the app staying alive in the background.
@MainActor
@Observable
final class TimerEngine {
    static let shared = TimerEngine()

    static let roundLength: TimeInterval = 10 * 60
    static let notificationCategory = "HOTPOT_ROUND"
    static let restartActionID = "HOTPOT_RESTART"
    /// iOS keeps at most 64 pending local notifications per app. 48 rounds = 8 hours of hotpot,
    /// and the queue is topped up every time the app opens.
    private static let roundsToSchedule = 48

    private typealias Keys = SharedStore.Keys

    /// Start of round 1, or nil when stopped.
    private(set) var anchor: Date?
    private(set) var totalPlates: Int

    /// App Group defaults, so the StandBy widget can read the timer too.
    private let defaults = SharedStore.defaults
    private var rolloverTask: Task<Void, Never>?

    private init() {
        SharedStore.migrateFromStandardDefaults()
        anchor = defaults.object(forKey: Keys.anchor) as? Date
        totalPlates = defaults.integer(forKey: Keys.totalPlates)
    }

    var isRunning: Bool { anchor != nil }

    // MARK: - Round math

    /// 0-based index of the round in progress at `date`.
    func roundIndex(at date: Date = .now) -> Int {
        guard let anchor else { return 0 }
        return max(0, Int(date.timeIntervalSince(anchor) / Self.roundLength))
    }

    func currentRound(at date: Date = .now) -> (start: Date, end: Date, number: Int)? {
        guard let anchor else { return nil }
        let index = roundIndex(at: date)
        let start = anchor.addingTimeInterval(Double(index) * Self.roundLength)
        return (start, start.addingTimeInterval(Self.roundLength), index + 1)
    }

    func remaining(at date: Date = .now) -> TimeInterval {
        guard let round = currentRound(at: date) else { return Self.roundLength }
        return max(0, round.end.timeIntervalSince(date))
    }

    // MARK: - Controls

    func start() async {
        if isRunning {
            await sync()
        } else {
            await restart()
        }
    }

    /// Countdown back to 10:00 from now; all pending notifications are replaced.
    func restart() async {
        setAnchor(.now)
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        await scheduleNotifications()
        await refreshLiveActivity()
        scheduleRollover()
    }

    func stop() async {
        setAnchor(nil)
        rolloverTask?.cancel()
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: await pendingRoundIDs())
        center.removeAllDeliveredNotifications()
        await endLiveActivities()
    }

    /// Bring notifications and the Live Activity up to date with the current round.
    /// Called when the app opens, a round rolls over, or a notification is tapped.
    func sync() async {
        guard isRunning else {
            await endLiveActivities()
            return
        }
        await scheduleNotifications()
        await refreshLiveActivity()
        scheduleRollover()
    }

    func setTotalPlates(_ total: Int) async {
        guard total != totalPlates else { return }
        totalPlates = total
        defaults.set(total, forKey: Keys.totalPlates)
        reloadWidgets()
        if isRunning { await refreshLiveActivity() }
    }

    func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.orderTimerWidgetKind)
    }

    func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Private

    private func setAnchor(_ date: Date?) {
        anchor = date
        defaults.set(date, forKey: Keys.anchor)
        reloadWidgets()
    }

    private func pendingRoundIDs() async -> [String] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix("hotpot.round.") }
    }

    private func scheduleNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: await pendingRoundIDs())

        guard let anchor else { return }
        let now = Date.now
        let firstRoundEnding = roundIndex(at: now) + 1

        for round in firstRoundEnding..<(firstRoundEnding + Self.roundsToSchedule) {
            // A restart/stop happened while we were awaiting; that call owns the schedule now.
            guard self.anchor == anchor else { return }

            let fireDate = anchor.addingTimeInterval(Double(round) * Self.roundLength)
            let content = UNMutableNotificationContent()
            content.title = "Order time! 📲"
            content.body = "10 minutes up — order more on the tablet! 🥩"
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            content.categoryIdentifier = Self.notificationCategory
            content.threadIdentifier = "hotpot"

            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: fireDate.timeIntervalSince(now),
                repeats: false
            )
            let request = UNNotificationRequest(identifier: "hotpot.round.\(round)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    /// While the app is in the foreground, move the Live Activity to the next round as each one ends.
    /// When the app is suspended this task simply pauses; `sync()` catches up on the next open.
    private func scheduleRollover() {
        rolloverTask?.cancel()
        guard let end = currentRound()?.end else { return }
        rolloverTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0.1, end.timeIntervalSinceNow) + 0.1))
            guard !Task.isCancelled, let self else { return }
            await self.refreshLiveActivity()
            self.scheduleRollover()
        }
    }

    private func refreshLiveActivity() async {
        guard let round = currentRound() else {
            await endLiveActivities()
            return
        }
        let state = HotpotActivityAttributes.ContentState(
            roundStart: round.start,
            roundEnd: round.end,
            round: round.number,
            totalPlates: totalPlates
        )
        // Marked stale when the round ends, so the widget can say "order now" if the
        // app isn't around to roll it over.
        let content = ActivityContent(state: state, staleDate: round.end)

        let activities = Activity<HotpotActivityAttributes>.activities
        if let current = activities.first {
            await current.update(content)
            for extra in activities.dropFirst() {
                await extra.end(nil, dismissalPolicy: .immediate)
            }
        } else if ActivityAuthorizationInfo().areActivitiesEnabled {
            do {
                _ = try Activity.request(attributes: HotpotActivityAttributes(), content: content, pushType: nil)
            } catch {
                print("Live Activity request failed: \(error)")
            }
        }
    }

    private func endLiveActivities() async {
        for activity in Activity<HotpotActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
