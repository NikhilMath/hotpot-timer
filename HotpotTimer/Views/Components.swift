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
            .font(Theme.rounded(20))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(background, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(Color.white.opacity(kind == .flame ? 0.25 : 0.08), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(duration: 0.18), value: configuration.isPressed)
    }

    private var background: AnyShapeStyle {
        switch kind {
        case .flame: AnyShapeStyle(Theme.flame)
        case .plain: AnyShapeStyle(Color.white.opacity(0.10))
        case .danger: AnyShapeStyle(Color(red: 0.45, green: 0.08, blue: 0.06))
        }
    }
}

struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}

extension TimeInterval {
    /// "1h 25m", "42m"
    var hotpotDuration: String {
        Duration.seconds(self).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}
