import SwiftUI

enum Theme {
    static let orange = Color(red: 1.00, green: 0.56, blue: 0.10)
    static let red = Color(red: 0.93, green: 0.22, blue: 0.12)
    static let ember = Color(red: 0.09, green: 0.05, blue: 0.04)

    static let flame = LinearGradient(
        colors: [Color(red: 1.00, green: 0.70, blue: 0.15), orange, red],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = LinearGradient(
        colors: [Color(red: 0.16, green: 0.06, blue: 0.03), ember, .black],
        startPoint: .top,
        endPoint: .bottom
    )

    static let card = Color.white.opacity(0.07)
    static let cardStroke = Color.white.opacity(0.08)

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}
