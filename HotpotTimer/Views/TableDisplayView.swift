import SwiftData
import SwiftUI
import UIKit

/// Landscape "table display": prop the phone up sideways and everyone at the table
/// can see the next-order countdown and the group's plate count.
struct TableDisplayView: View {
    @Query(sort: \MeatType.sortOrder) private var meats: [MeatType]
    @AppStorage(SharedStore.Keys.people, store: SharedStore.defaults) private var people = 1
    @State private var glow = false

    private let engine = TimerEngine.shared

    private var total: Int { meats.reduce(0) { $0 + $1.count } }
    private var perPerson: Double { Double(total) / Double(max(1, people)) }

    var body: some View {
        GeometryReader { geo in
            let ring = min(geo.size.height * 0.88, geo.size.width * 0.42)

            TimelineView(.periodic(from: .now, by: 0.25)) { timeline in
                HStack(spacing: 0) {
                    countdown(at: timeline.date, size: ring)
                        .frame(maxWidth: .infinity)

                    Capsule()
                        .fill(Theme.flame)
                        .frame(width: 3, height: ring * 0.65)
                        .opacity(0.5)

                    plates(height: ring)
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background { background }
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Sitting on the table; don't let the screen sleep.
            UIApplication.shared.isIdleTimerDisabled = true
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }

    private var background: some View {
        ZStack {
            Color.black
            RadialGradient(
                colors: [Theme.red.opacity(glow ? 0.38 : 0.22), Theme.ember.opacity(0.6), .clear],
                center: UnitPoint(x: 0.5, y: 1.15),
                startRadius: 20,
                endRadius: glow ? 620 : 520
            )
            RadialGradient(
                colors: [Theme.orange.opacity(glow ? 0.16 : 0.08), .clear],
                center: UnitPoint(x: 0.25, y: 0.5),
                startRadius: 10,
                endRadius: 360
            )
        }
        .ignoresSafeArea()
    }

    private func countdown(at date: Date, size: CGFloat) -> some View {
        let remaining = engine.remaining(at: date)
        let progress = engine.isRunning ? remaining / TimerEngine.roundLength : 1
        let lineWidth = size * 0.05

        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.06), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Theme.flame, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Theme.red.opacity(0.7), radius: 18)
                .animation(.linear(duration: 0.25), value: progress)

            VStack(spacing: size * 0.015) {
                Text(engine.isRunning ? "NEXT ORDER" : "READY")
                    .font(Theme.rounded(size * 0.06, .bold))
                    .tracking(3)
                    .foregroundStyle(Theme.orange)
                Text(TimerCard.format(remaining))
                    .font(Theme.rounded(size * 0.26))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .contentTransition(.numericText(countsDown: true))
                Text(engine.isRunning ? "📲 ROUND \(engine.roundIndex(at: date) + 1)" : "📲 tap Start in portrait")
                    .font(Theme.rounded(size * 0.05, .semibold))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .frame(width: size, height: size)
    }

    private func plates(height: CGFloat) -> some View {
        VStack(spacing: height * 0.02) {
            Text(people > 1 ? "GROUP TOTAL" : "TOTAL")
                .font(Theme.rounded(height * 0.06, .bold))
                .tracking(4)
                .foregroundStyle(Theme.orange)

            Text("\(total)")
                .font(Theme.rounded(height * 0.42, .black))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundStyle(Theme.flame)
                .shadow(color: Theme.red.opacity(0.45), radius: 20)
                .contentTransition(.numericText(value: Double(total)))
                .animation(.snappy, value: total)

            Text(total == 1 ? "plate of meat 🥩" : "plates of meat 🥩")
                .font(Theme.rounded(height * 0.055, .semibold))
                .foregroundStyle(.white.opacity(0.65))

            if people > 1 {
                Text("👥 \(people) people · \(perPerson.platesString) each")
                    .font(Theme.rounded(height * 0.05, .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: Capsule())
                    .padding(.top, height * 0.02)
            }

            let eaten = meats.filter { $0.count > 0 }.prefix(6)
            if !eaten.isEmpty {
                HStack(spacing: 14) {
                    ForEach(Array(eaten)) { meat in
                        Text("\(meat.emoji) \(meat.count)")
                            .font(Theme.rounded(height * 0.05, .bold))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .padding(.top, height * 0.01)
            }
        }
        .padding(.horizontal, 12)
    }
}
