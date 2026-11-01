import ActivityKit
import AppIntents
import SwiftUI
import WidgetKit

struct HotpotLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: HotpotActivityAttributes.self) { context in
            LockScreenView(state: context.state, isStale: context.isStale)
                .activityBackgroundTint(Theme.sumi.opacity(0.92))
                .activitySystemActionForegroundColor(Theme.gold)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("注文 ORDER UP")
                            .font(Theme.font(13, .bold))
                            .foregroundStyle(Theme.gold)
                        Text("again in")
                            .font(Theme.font(15, .semibold))
                            .foregroundStyle(Theme.washi.opacity(0.7))
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("🥩 \(context.state.platesText)")
                        .font(Theme.font(15, .bold))
                        .foregroundStyle(Theme.washi)
                        .padding(.trailing, 4)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 0) {
                            Countdown(state: context.state)
                                .font(Theme.font(46))
                                .foregroundStyle(Theme.vermilion)
                            if context.isStale {
                                Text("Order on the tablet! 📲")
                                    .font(Theme.font(13, .semibold))
                                    .foregroundStyle(Theme.washi.opacity(0.7))
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
                    .font(Theme.font(15, .bold))
                    .foregroundStyle(Theme.gold)
                    .frame(width: 44)
            } minimal: {
                Countdown(state: context.state)
                    .font(Theme.font(11, .bold))
                    .foregroundStyle(Theme.gold)
                    .minimumScaleFactor(0.6)
            }
            .keylineTint(Theme.gold)
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
                .font(Theme.font(17, .heavy))
                .foregroundStyle(Theme.washi)
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
                .background(Theme.vermilion, in: Capsule())
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
                Text("注文 · ORDER UP AGAIN IN")
                    .font(Theme.font(13, .bold))
                    .foregroundStyle(Theme.gold)
                Countdown(state: state)
                    .font(Theme.font(48))
                    .foregroundStyle(Theme.washi)
                Text(isStale ? "Time's up — order more! 📲" : "🥩 \(state.platesText)")
                    .font(Theme.font(15, .semibold))
                    .foregroundStyle(Theme.washi.opacity(0.75))
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
