import SwiftUI

/// P-AI typography tokens — map từ tokens/typography.css.
/// Hiện dùng system font với weight/tracking tương đương Epilogue;
/// khi bundle Epilogue thật chỉ cần đổi tại đây.
enum PAIFont {
    static let display = Font.system(size: 40, weight: .heavy)
    static let h1      = Font.system(size: 32, weight: .bold)
    static let h2      = Font.system(size: 24, weight: .bold)
    static let h3      = Font.system(size: 20, weight: .semibold)
    static let lg      = Font.system(size: 18, weight: .medium)
    static let body    = Font.system(size: 16, weight: .regular)
    static let sm      = Font.system(size: 14, weight: .regular)
    static let xs      = Font.system(size: 12, weight: .medium)
    static let mono    = Font.system(size: 13, design: .monospaced)
}

enum PAITracking {
    static let tight: CGFloat = -1.2  // display, −0.03em
    static let caps: CGFloat = 1.0    // eyebrow, +0.08em
}

/// Eyebrow label: UPPERCASE, 12px, wide tracking — "GOOD MORNING", "COLORS"
struct PAIEyebrow: View {
    let text: String

    var body: some View {
        Text(text.uppercased())
            .font(PAIFont.xs)
            .tracking(PAITracking.caps)
            .foregroundStyle(PAIColor.textMuted)
    }
}
