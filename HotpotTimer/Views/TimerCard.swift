import SwiftUI

struct TimerCard: View {
    private let engine = TimerEngine.shared

    var body: some View {
        VStack(spacing: 24) {
            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                dial(at: timeline.date)
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                Button {
                    Haptics.tap(.heavy)
                    SessionClock.markStartedIfNeeded()
                    Task { await engine.start() }
                } label: {
                    buttonLabel("Start", systemImage: "play.fill")
                }
                .buttonStyle(ChunkyButtonStyle(kind: .flame, height: 84))
                .disabled(engine.isRunning)
                .opacity(engine.isRunning ? 0.35 : 1)

                Button {
                    Haptics.tap(.heavy)
                    SessionClock.markStartedIfNeeded()
                    Task { await engine.restart() }
                } label: {
                    buttonLabel("Restart", systemImage: "arrow.clockwise")
                }
                .buttonStyle(ChunkyButtonStyle(kind: engine.isRunning ? .flame : .plain, height: 84))

                Button {
                    Haptics.tap(.heavy)
                    Task { await engine.stop() }
                } label: {
                    buttonLabel("Stop", systemImage: "stop.fill")
                }
                .buttonStyle(ChunkyButtonStyle(kind: .danger, height: 84))
                .disabled(!engine.isRunning)
                .opacity(engine.isRunning ? 1 : 0.35)
            }
        }
        .padding(20)
        .card()
    }

    private func dial(at date: Date) -> some View {
        let remaining = engine.remaining(at: date)
        let progress = engine.isRunning ? remaining / TimerEngine.roundLength : 1

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.07), lineWidth: 16)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.flame, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.red.opacity(0.6), radius: 12)
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: 2) {
                Text(engine.isRunning ? "ROUND \(engine.roundIndex(at: date) + 1)" : "READY")
                    .font(Theme.rounded(16, .bold))
                    .tracking(3)
                    .foregroundStyle(Theme.orange)
                Text(Self.format(remaining))
                    .font(Theme.rounded(76))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                Text("📲 until next order")
                    .font(Theme.rounded(14, .semibold))
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: 260, height: 260)
    }

    private func buttonLabel(_ title: String, systemImage: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage).font(.system(size: 24, weight: .heavy))
            Text(title)
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let seconds = Int(interval.rounded(.up))
        return String(format: "%d:%02d", seconds / 60, seconds % 60)
    }
}
