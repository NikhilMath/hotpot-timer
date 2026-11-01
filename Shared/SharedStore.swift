import Foundation

/// State the app shares with its widgets through the App Group container.
enum SharedStore {
    /// Must match the App Group in both targets' entitlements.
    static let appGroup = "group.com.nikhilmath.hotpottimer"
    static let orderTimerWidgetKind = "OrderTimerWidget"

    static let defaults = UserDefaults(suiteName: appGroup) ?? .standard

    enum Keys {
        static let anchor = "timer.anchor"
        static let totalPlates = "meat.totalPlates"
        static let people = "session.people"
    }

    static var anchor: Date? { defaults.object(forKey: Keys.anchor) as? Date }
    static var totalPlates: Int { defaults.integer(forKey: Keys.totalPlates) }
    static var people: Int { max(1, defaults.integer(forKey: Keys.people)) }

    /// Earlier builds kept these in the app's own defaults; copy them over once.
    static func migrateFromStandardDefaults() {
        let standard = UserDefaults.standard
        let migratedKey = "sharedStore.migrated"
        guard !defaults.bool(forKey: migratedKey) else { return }
        for key in [Keys.anchor, Keys.totalPlates, Keys.people] {
            if let value = standard.object(forKey: key), defaults.object(forKey: key) == nil {
                defaults.set(value, forKey: key)
            }
        }
        defaults.set(true, forKey: migratedKey)
    }

    /// Round in progress at `date` for a timer started at `anchor`.
    static func round(anchor: Date, at date: Date, length: TimeInterval = 10 * 60) -> (start: Date, end: Date, number: Int) {
        let index = max(0, Int(date.timeIntervalSince(anchor) / length))
        let start = anchor.addingTimeInterval(Double(index) * length)
        return (start, start.addingTimeInterval(length), index + 1)
    }
}
