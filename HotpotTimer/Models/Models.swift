import Foundation
import SwiftData

@Model
final class MeatType {
    var name: String
    var emoji: String
    var count: Int
    var sortOrder: Int
    var isCustom: Bool

    init(name: String, emoji: String, sortOrder: Int, isCustom: Bool, count: Int = 0) {
        self.name = name
        self.emoji = emoji
        self.count = count
        self.sortOrder = sortOrder
        self.isCustom = isCustom
    }

    static let builtIns: [(name: String, emoji: String)] = [
        ("Beef", "🐄"),
        ("Pork", "🐷"),
        ("Chicken", "🐔"),
        ("Lamb", "🐑"),
        ("Seafood", "🦐"),
    ]
}

struct MeatTally: Codable, Hashable {
    var name: String
    var emoji: String
    var count: Int
}

@Model
final class SessionRecord {
    var date: Date
    var duration: TimeInterval
    /// Group total across everyone at the table.
    var total: Int
    /// Defaulted so sessions saved before this field existed migrate automatically.
    var people: Int = 1
    /// JSON-encoded `[MeatTally]`; plain Data keeps the SwiftData schema simple.
    var talliesData: Data

    init(date: Date, duration: TimeInterval, total: Int, people: Int, tallies: [MeatTally]) {
        self.date = date
        self.duration = duration
        self.total = total
        self.people = max(1, people)
        self.talliesData = (try? JSONEncoder().encode(tallies)) ?? Data()
    }

    var tallies: [MeatTally] {
        (try? JSONDecoder().decode([MeatTally].self, from: talliesData)) ?? []
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
