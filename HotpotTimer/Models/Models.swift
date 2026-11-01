import Foundation
import SwiftData

@Model
final class SessionRecord {
    var date: Date
    var duration: TimeInterval
    /// Group total across everyone at the table.
    var total: Int
    /// Defaulted so sessions saved before this field existed migrate automatically.
    var people: Int = 1
    /// Per-meat breakdown from older versions. No longer written or shown; kept so
    /// existing stores open without a migration.
    var talliesData: Data = Data()

    init(date: Date, duration: TimeInterval, total: Int, people: Int) {
        self.date = date
        self.duration = duration
        self.total = total
        self.people = max(1, people)
    }

    var perPerson: Double { Double(total) / Double(max(1, people)) }
}

extension Double {
    /// "3.5", "4"
    var platesString: String {
        formatted(.number.precision(.fractionLength(0...1)))
    }
}

/// When the current eating session began: the first Start or first plate, whichever comes first.
enum SessionClock {
    private static let key = "session.startedAt"

    static var startedAt: Date? {
        UserDefaults.standard.object(forKey: key) as? Date
    }

    static func markStartedIfNeeded() {
        if startedAt == nil { UserDefaults.standard.set(Date.now, forKey: key) }
    }

    static func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
