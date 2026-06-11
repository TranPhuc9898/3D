import SwiftUI

/// P-AI spacing/radius/shadow/motion tokens — map từ tokens/spacing.css (4px grid).
enum PAISpace {
    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 20
    static let s6: CGFloat = 24
    static let s8: CGFloat = 32
    static let s12: CGFloat = 48
}

enum PAIRadius {
    static let sm: CGFloat = 6
    static let md: CGFloat = 10
    static let lg: CGFloat = 14    // cards, chips
    static let xl: CGFloat = 20    // sheets
    static let xxl: CGFloat = 28   // palette cards
    static let composer: CGFloat = 22
}

enum PAIDuration {
    static let fast: Double = 0.12
    static let base: Double = 0.20
}

extension View {
    /// Shadow tím nhạt, thấp và mềm — không dùng shadow đen gắt.
    func paiShadowSoft() -> some View {
        shadow(color: Color(hex: 0x2E1065, opacity: 0.08), radius: 12, y: 4)
    }

    /// Glow màu brand cho primary button.
    func paiShadowBrand() -> some View {
        shadow(color: Color(hex: 0x5B21B6, opacity: 0.30), radius: 24, y: 8)
    }
}
