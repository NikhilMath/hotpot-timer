import ActivityKit
import Foundation
import Observation
import UserNotifications

/// Owns the repeating 10-minute timer.
///
/// The timer is just an anchor date: round N ends at `anchor + N × 10 min`. Everything else
/// (the on-screen countdown, pending notifications, the Live Activity) is derived from it,
/// so nothing depends on the app staying alive in the background.
///
/// The anchor lives in the App Group, and the widget extension can restart the timer through
/// `OrderTimerCore` while the app isn't running, so `sync()` re-reads it before doing anything.
@MainActor
@Observable
final class TimerEngine {
    static let shared = TimerEngine()

    static let roundLength = OrderTimerCore.roundLength
    static let notificationCategory = OrderTimerCore.notificationCategory
    static let restartActionID = OrderTimerCore.restartActionID

    private typealias Keys = SharedStore.Keys

    /// Start of round 1, or nil when stopped.
    private(set) var anchor: Date?
    private(set) var totalPlates: Int

    /// App Group defaults, so the widgets can read the timer too.
    private let defaults = SharedStore.defaults
    private var rolloverTask: Task<Void, Never>?

    private init() {
        SharedStore.migrateFromStandardDefaults()
        anchor = SharedStore.anchor
        totalPlates = SharedStore.totalPlates
    }

    var isRunning: Bool { anchor != nil }

    // MARK: - Round math

    /// 0-based index of the round in progress at `date`.
    func roundIndex(at date: Date = .now) -> Int {
        currentRound(at: date).map { $0.number - 1 } ?? 0
    }

    func currentRound(at date: Date = .now) -> (start: Date, end: Date, number: Int)? {
        guard let anchor else { return nil }
        return SharedStore.round(anchor: anchor, at: date, length: Self.roundLength)
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
        let now = Date.now
        anchor = now
        await OrderTimerCore.restart(at: now)
        await refreshLiveActivity()
        scheduleRollover()
    }

    func stop() async {
        anchor = nil
        defaults.removeObject(forKey: Keys.anchor)
        rolloverTask?.cancel()
        await OrderTimerCore.removePendingRounds()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        await OrderTimerCore.endLiveActivities()
        OrderTimerCore.reloadWidgets()
    }

    /// Bring notifications and the Live Activity up to date with the current round.
    /// Called when the app opens, a round rolls over, or a notification is tapped.
    func sync() async {
        anchor = SharedStore.anchor
        guard let anchor else {
            rolloverTask?.cancel()
            await OrderTimerCore.endLiveActivities()
            return
        }
        await OrderTimerCore.scheduleNotifications(anchor: anchor)
        await refreshLiveActivity()
        scheduleRollover()
    }

    /// The group's plate count; persisted in the App Group so widgets and the Live Activity see it.
    func setTotalPlates(_ total: Int) {
        let total = max(0, total)
        guard total != totalPlates else { return }
        totalPlates = total
        defaults.set(total, forKey: Keys.totalPlates)
        reloadWidgets()
        if isRunning { Task { await refreshLiveActivity() } }
    }

    func addPlates(_ delta: Int) {
        setTotalPlates(totalPlates + delta)
    }

    func reloadWidgets() {
        OrderTimerCore.reloadWidgets()
    }

    func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    // MARK: - Private

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

    /// Updates the running Live Activity, or starts one (only possible from the app).
    private func refreshLiveActivity() async {
        guard let anchor else {
            await OrderTimerCore.endLiveActivities()
            return
        }
        if await OrderTimerCore.updateLiveActivities(anchor: anchor) { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        do {
            _ = try Activity.request(
                attributes: HotpotActivityAttributes(),
                content: OrderTimerCore.liveActivityContent(anchor: anchor),
                pushType: nil
            )
        } catch {
            print("Live Activity request failed: \(error)")
        }
    }
}
