import ActivityKit
import Foundation

/// Shared by the app (which starts/updates the activity) and the widget extension (which draws it).
struct HotpotActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// Start and end of the round currently counting down.
        var roundStart: Date
        var roundEnd: Date
        /// 1-based round number.
        var round: Int
        var totalPlates: Int
    }
}

extension HotpotActivityAttributes.ContentState {
    var platesText: String {
        totalPlates == 1 ? "1 plate" : "\(totalPlates) plates"
    }
}
