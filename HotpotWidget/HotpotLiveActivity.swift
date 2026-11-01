import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct HotpotLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HotpotActivityAttributes.self) { context in
            LockScreenView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(Theme.ember.opacity(0.92))
                .activitySystemActionForegroundColor(Theme.orange)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("🍲 HOTPOT")
                            .font(Theme.rounded(13, .bold))
                            .foregroundStyle(Theme.orange)
                        Text("Round \(context.state.round)")
                            .font(Theme.rounded(15, .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("🥩 \(context.state.platesText)")
                        .font(Theme.rounded(15, .bold))
                        .foregroundStyle(.white)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 0) {
                            Countdown(state: context.state)
                                .font(Theme.rounded(46))
                                .foregroundStyle(Theme.flame)
                            if context.isStale {
                                Text("Order on the tablet! 📲")
                                    .font(Theme.rounded(13, .semibold))
                                    .foregroundStyle(.white.opacity(0.7))
                            }
                        }
                        Spacer()
                        RestartButton()
                    }
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Text("🍲")
            } compactTrailing: {
                Countdown(state: context.state)
                    .font(Theme.rounded(15, .bold))
                    .foregroundStyle(Theme.orange)
                    .frame(width: 44)
            } minimal: {
                Countdown(state: context.state)
                    .font(Theme.rounded(11, .bold))
                    .foregroundStyle(Theme.orange)
                    .minimumScaleFactor(0.6)
            }
            .keylineTint(Theme.orange)
        }
    }
}

/// Ticks on its own between updates; no timeline or push needed.
private struct Countdown: View {
    let state: HotpotActivityAttributes.ContentState

    var body: some View {
        Text(timerInterval: state.roundStart...state.roundEnd, countsDown: true)
            .monospacedDigit()
            .multilineTextAlignment(.center)
    }
}

private struct RestartButton: View {
    var body: some View {
        Button(intent: RestartTimerIntent()) {
            Label("Restart", systemImage: "arrow.clockwise")
                .font(Theme.rounded(17, .heavy))
                .foregroundStyle(.white)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.flame, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct LockScreenView: View {
    let state: HotpotActivityAttributes.ContentState
    let isStale: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text("🍲 HOTPOT · ROUND \(state.round)")
                    .font(Theme.rounded(13, .bold))
                    .foregroundStyle(Theme.orange)
                Countdown(state: state)
                    .font(Theme.rounded(48))
                    .foregroundStyle(.white)
                Text(isStale ? "Time's up — order more! 📲" : "🥩 \(state.platesText)")
                    .font(Theme.rounded(15, .semibold))
                    .foregroundStyle(.white.opacity(0.75))
            }
            Spacer(minLength: 0)
            RestartButton()
        }
        .padding(16)
    }
}

#Preview("Lock Screen", as: .content, using: HotpotActivityAttributes()) {
    HotpotLiveActivity()
} contentStates: {
    HotpotActivityAttributes.ContentState(roundStart: .now, roundEnd: .now.addingTimeInterval(600), round: 3, totalPlates: 14)
}

#Preview("Expanded", as: .dynamicIsland(.expanded), using: HotpotActivityAttributes()) {
    HotpotLiveActivity()
} contentStates: {
    HotpotActivityAttributes.ContentState(roundStart: .now, roundEnd: .now.addingTimeInterval(600), round: 3, totalPlates: 14)
}
