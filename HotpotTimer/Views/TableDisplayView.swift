import SwiftUI
import UIKit

/// Landscape "table display": prop the phone up sideways and everyone at the table can see
/// when to order again and the group's plate count, and tap to restart or add plates.
struct TableDisplayView: View {
    @AppStorage(SharedStore.Keys.people, store: SharedStore.defaults) private var people = 1

    private let engine = TimerEngine.shared

    /// OLED burn-in guard: the two halves swap sides this often, with a slight drift in between.
    private static let swapInterval: TimeInterval = 3 * 60

    private var total: Int { engine.totalPlates }
    private var perPerson: Double { Double(total) / Double(max(1, people)) }

    var body: some View {
        GeometryReader { geo in
            let ring = min(geo.size.height * 0.92, geo.size.width * 0.42)

            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                let phase = Int(timeline.date.timeIntervalSince1970 / Self.swapInterval)
                let swapped = phase.isMultiple(of: 2) == false
                let drift = CGFloat(phase % 3 - 1) * 6

                HStack(spacing: 0) {
                    countdown(at: timeline.date, size: ring)
                        .frame(maxWidth: .infinity)
                        .environment(\.layoutDirection, .leftToRight)

                    Rectangle()
                        .fill(Theme.gold.opacity(0.35))
                        .frame(width: 1, height: ring * 0.7)

                    plates(height: ring)
                        .frame(maxWidth: .infinity)
                        .environment(\.layoutDirection, .leftToRight)
                }
                // Flipping layout direction swaps the halves without duplicating views.
                .environment(\.layoutDirection, swapped ? .rightToLeft : .leftToRight)
                .offset(y: drift)
                .animation(.easeInOut(duration: 1.2), value: swapped)
                .animation(.easeInOut(duration: 1.2), value: drift)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background { JapaneseBackground() }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Sitting on the table; don't let the screen sleep.
            UIApplication.shared.isIdleTimerDisabled = true
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    // MARK: - Countdown half

    private func countdown(at date: Date, size: CGFloat) -> some View {
        let remaining = engine.remaining(at: date)
        let progress = engine.isRunning ? remaining / TimerEngine.roundLength : 1
        let lineWidth = size * 0.04

        return ZStack {
            Circle()
                .stroke(Theme.gold.opacity(0.12), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.vermilion, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.shu.opacity(0.6), radius: 14)
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: size * 0.012) {
                Text("注文")
                    .font(Theme.mincho(size * 0.075))
                    .foregroundStyle(Theme.shu)
                Text(engine.isRunning ? "ORDER UP AGAIN IN" : "READY")
                    .font(Theme.font(size * 0.042, .bold))
                    .tracking(2)
                    .foregroundStyle(Theme.gold)
                Text(TimerCard.format(remaining))
                    .font(Theme.font(size * 0.22))
                    .monospacedDigit()
                    .foregroundStyle(Theme.washi)
                    .contentTransition(.numericText(countsDown: true))

                Button {
                    Haptics.tap(.heavy)
                    SessionClock.markStartedIfNeeded()
                    Task { await engine.restart() }
                } label: {
                    Label(engine.isRunning ? "Restart" : "Start", systemImage: engine.isRunning ? "arrow.clockwise" : "play.fill")
                        .font(Theme.font(size * 0.052, .bold))
                        .foregroundStyle(Theme.washi)
                        .padding(.horizontal, size * 0.06)
                        .padding(.vertical, size * 0.03)
                        .background(Theme.vermilion, in: Capsule())
                        .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.55), lineWidth: 1))
                }
                .buttonStyle(.plain)
                .padding(.top, size * 0.01)
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Plates half

    private func plates(height: CGFloat) -> some View {
        VStack(spacing: height * 0.02) {
            HankoLabel(kanji: "合計", english: people > 1 ? "GROUP TOTAL" : "TOTAL")

            Text("\(total)")
                .font(Theme.font(height * 0.32, .black))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Theme.vermilion)
                .shadow(color: Theme.shu.opacity(0.4), radius: 16)
                .contentTransition(.numericText(value: Double(total)))
                .animation(.snappy, value: total)

            Text(total == 1 ? "plate of meat" : "plates of meat")
                .font(Theme.font(height * 0.045, .semibold))
                .foregroundStyle(Theme.washi.opacity(0.65))

            if people > 1 {
                Text("人数 \(people) · \(perPerson.platesString) each")
                    .font(Theme.font(height * 0.045, .bold))
                    .foregroundStyle(Theme.washi)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .overlay(Capsule().strokeBorder(Theme.gold.opacity(0.35), lineWidth: 1))
            }

            HStack(spacing: 10) {
                Button {
                    Haptics.tap(.light)
                    engine.addPlates(-1)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: height * 0.07, weight: .heavy))
                }
                .buttonStyle(ChunkyButtonStyle(kind: .plain, height: height * 0.2))
                .frame(width: height * 0.2)
                .disabled(total == 0)
                .opacity(total == 0 ? 0.4 : 1)
                .accessibilityLabel("Remove one plate")

                Button {
                    Haptics.tap(.heavy)
                    SessionClock.markStartedIfNeeded()
                    engine.addPlates(1)
                } label: {
                    Label("1 plate", systemImage: "plus")
                        .font(Theme.font(height * 0.07))
                }
                .buttonStyle(ChunkyButtonStyle(kind: .flame, height: height * 0.2))
                .frame(maxWidth: height * 0.75)
                .accessibilityLabel("Add one plate")
            }
            .padding(.top, height * 0.03)
        }
        .padding(.horizontal, 12)
    }
}
