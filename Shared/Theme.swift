import SwiftUI

/// Japanese izakaya look: sumi-ink black, vermilion (朱 shu) lacquer, gold leaf and washi paper.
enum Theme {
    /// 朱 vermilion, torii-gate red.
    static let shu = Color(red: 0.86, green: 0.25, blue: 0.16)
    /// 紅 deep crimson.
    static let beni = Color(red: 0.62, green: 0.10, blue: 0.13)
    /// 金 gold leaf, for labels and hairlines.
    static let gold = Color(red: 0.84, green: 0.69, blue: 0.40)
    /// 和紙 washi paper, for text.
    static let washi = Color(red: 0.96, green: 0.93, blue: 0.87)
    /// 墨 sumi ink.
    static let sumi = Color(red: 0.075, green: 0.066, blue: 0.062)

    /// Lacquerware red: buttons, big numbers, the countdown ring.
    static let vermilion = LinearGradient(
        colors: [Color(red: 0.94, green: 0.38, blue: 0.22), shu, beni],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let background = LinearGradient(
        colors: [Color(red: 0.13, green: 0.10, blue: 0.09), sumi, .black],
        startPoint: .top,
        endPoint: .bottom
    )

    static let card = washi.opacity(0.045)
    static let cardStroke = gold.opacity(0.22)
    static let cornerRadius: CGFloat = 14

    /// Serif (New York) for Latin text and numbers; reads like Mincho next to the kanji.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    /// Hiragino Mincho for kanji labels.
    static func mincho(_ size: CGFloat) -> Font {
        .custom("HiraMinProN-W6", size: size)
    }
}
