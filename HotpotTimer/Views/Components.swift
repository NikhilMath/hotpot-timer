import SwiftUI
import UIKit

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

/// Big, squishy buttons that are easy to hit with chopstick-greasy fingers.
struct ChunkyButtonStyle: ButtonStyle {
    enum Kind { case flame, plain, danger }

    var kind: Kind = .flame
    var height: CGFloat = 72

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(20))
            .foregroundStyle(Theme.washi)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(background, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.gold.opacity(kind == .flame ? 0.55 : 0.22), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(duration: 0.18), value: configuration.isPressed)
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .flame: AnyShapeStyle(Theme.vermilion)
        case .plain: AnyShapeStyle(Theme.washi.opacity(0.08))
        case .danger: AnyShapeStyle(Theme.beni.opacity(0.55))
        }
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

/// 青海波 seigaiha: overlapping wave scales, drawn faintly in gold behind the screen.
struct SeigaihaPattern: View {
    var radius: CGFloat = 26
    var color: Color = Theme.gold

    var body: some View {
        Canvas { context, size in
            let rowStep = radius * 0.5
            let rows = Int(size.height / rowStep) + 2
            let cols = Int(size.width / (radius * 2)) + 2
            for row in 0..<rows {
                let y = CGFloat(row) * rowStep
                let xOffset = row.isMultiple(of: 2) ? 0 : radius
                for col in -1..<cols {
                    let center = CGPoint(x: CGFloat(col) * radius * 2 + xOffset, y: y)
                    // Later rows paint over earlier ones, which gives the scale overlap.
                    let outer = Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
                    context.fill(outer, with: .color(Theme.sumi))
                    for ring in stride(from: radius, through: radius * 0.25, by: -radius * 0.25) {
                        let circle = Path(ellipseIn: CGRect(x: center.x - ring, y: center.y - ring, width: ring * 2, height: ring * 2))
                        context.stroke(circle, with: .color(color), lineWidth: 1)
                    }
                }
            }
        }
    }
}

/// Sumi background with a seigaiha band rising from the bottom.
struct JapaneseBackground: View {
    var body: some View {
        ZStack {
            Theme.background
            SeigaihaPattern()
                .opacity(0.10)
                .mask(LinearGradient(colors: [.clear, .black.opacity(0.4), .black], startPoint: .top, endPoint: .bottom))
                .blendMode(.screen)
        }
        .ignoresSafeArea()
        .drawingGroup()
    }
}

/// Small 朱 hanko-stamp label, e.g. 合計 above the total.
struct HankoLabel: View {
    let kanji: String
    let english: String

    var body: some View {
        HStack(spacing: 8) {
            Text(kanji)
                .font(Theme.mincho(13))
                .foregroundStyle(Theme.washi)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Theme.shu, in: RoundedRectangle(cornerRadius: 3))
            Text(english)
                .font(Theme.font(13, .bold))
                .tracking(3)
                .foregroundStyle(Theme.gold)
        }
    }
}

extension TimeInterval {
    /// "1h 25m", "42m"
    var hotpotDuration: String {
        Duration.seconds(self).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}
