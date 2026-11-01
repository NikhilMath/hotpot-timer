import AppIntents
import SwiftUI
import WidgetKit

/// Small widget for StandBy (and the Home Screen): next-order countdown plus the group's plates.
struct OrderTimerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStore.orderTimerWidgetKind, provider: OrderTimerProvider()) { entry in
            OrderTimerWidgetView(entry: entry)
        }
        .configurationDisplayName("Order Timer")
        .description("Countdown to your next tablet order and the group's plate count. Made for StandBy.")
        .supportedFamilies([.systemSmall])
    }
}

struct OrderTimerEntry: TimelineEntry {
    let date: Date
    /// Nil when the timer is stopped.
    let roundStart: Date?
    let roundEnd: Date?
    let round: Int
    let totalPlates: Int
    let people: Int

    var perPerson: Double { Double(totalPlates) / Double(max(1, people)) }
}

struct OrderTimerProvider: TimelineProvider {
    /// Rounds are fixed 10-minute steps from the anchor, so the whole evening can be laid out
    /// up front and the widget rolls over by itself even while the app is closed.
    private let roundsAhead = 48

    func placeholder(in context: Context) -> OrderTimerEntry {
        OrderTimerEntry(date: .now, roundStart: .now, roundEnd: .now.addingTimeInterval(600), round: 3, totalPlates: 14, people: 4)
    }

    func getSnapshot(in context: Context, completion: @escaping (OrderTimerEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : entries(from: .now, count: 1)[0])
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<OrderTimerEntry>) -> Void) {
        let isRunning = SharedStore.anchor != nil
        let entries = entries(from: .now, count: isRunning ? roundsAhead : 1)
        // The app reloads this timeline whenever the timer or counts change.
        completion(Timeline(entries: entries, policy: isRunning ? .atEnd : .never))
    }

    private func entries(from now: Date, count: Int) -> [OrderTimerEntry] {
        let plates = SharedStore.totalPlates
        let people = SharedStore.people
        guard let anchor = SharedStore.anchor else {
            return [OrderTimerEntry(date: now, roundStart: nil, roundEnd: nil, round: 0, totalPlates: plates, people: people)]
        }
        let current = SharedStore.round(anchor: anchor, at: now)
        return (0..<count).map { offset in
            let start = current.start.addingTimeInterval(Double(offset) * 600)
            return OrderTimerEntry(
                date: offset == 0 ? now : start,
                roundStart: start,
                roundEnd: start.addingTimeInterval(600),
                round: current.number + offset,
                totalPlates: plates,
                people: people
            )
        }
    }
}

struct OrderTimerWidgetView: View {
    let entry: OrderTimerEntry
    /// False in StandBy, where the system drops the background and goes full-bleed.
    @Environment(\.showsWidgetContainerBackground) private var showsBackground

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(entry.roundStart == nil ? "注文 READY" : "注文 ORDER UP")
                    .font(Theme.font(12, .bold))
                    .tracking(1.5)
                    .foregroundStyle(Theme.gold)
                Spacer(minLength: 4)
                Button(intent: RestartTimerIntent()) {
                    Image(systemName: entry.roundStart == nil ? "play.fill" : "arrow.clockwise")
                        .font(.system(size: 13, weight: .heavy))
                        .foregroundStyle(Theme.washi)
                        .frame(width: 30, height: 30)
                        .background(Theme.vermilion, in: Circle())
                }
                .buttonStyle(.plain)
            }

            Group {
                if let start = entry.roundStart, let end = entry.roundEnd {
                    Text(timerInterval: start...end, countsDown: true)
                } else {
                    Text("10:00")
                }
            }
            .font(Theme.font(42))
            .monospacedDigit()
            .foregroundStyle(Theme.washi)
            .lineLimit(1)
            .minimumScaleFactor(0.6)

            Text(entry.roundStart == nil ? "📲 tap ▶ to start" : "📲 again on the tablet")
                .font(Theme.font(11, .semibold))
                .foregroundStyle(Theme.washi.opacity(0.55))

            Spacer(minLength: 2)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(entry.totalPlates)")
                    .font(Theme.font(30, .black))
                    .monospacedDigit()
                    .foregroundStyle(Theme.vermilion)
                Text(entry.totalPlates == 1 ? "plate 🥩" : "plates 🥩")
                    .font(Theme.font(13, .bold))
                    .foregroundStyle(Theme.washi.opacity(0.75))
            }
            if entry.people > 1 {
                Text("👥 \(entry.people) · \(entry.perPerson.formatted(.number.precision(.fractionLength(0...1)))) each")
                    .font(Theme.font(11, .semibold))
                    .foregroundStyle(Theme.washi.opacity(0.6))
            }
        }
        .padding(showsBackground ? 0 : 4)
        .containerBackground(for: .widget) {
            ZStack {
                Theme.sumi
                RadialGradient(
                    colors: [Theme.shu.opacity(0.45), .clear],
                    center: .bottomTrailing,
                    startRadius: 4,
                    endRadius: 170
                )
            }
        }
    }
}

#Preview("Running", as: .systemSmall) {
    OrderTimerWidget()
} timeline: {
    OrderTimerEntry(date: .now, roundStart: .now, roundEnd: .now.addingTimeInterval(600), round: 3, totalPlates: 14, people: 4)
    OrderTimerEntry(date: .now, roundStart: nil, roundEnd: nil, round: 0, totalPlates: 0, people: 1)
}
