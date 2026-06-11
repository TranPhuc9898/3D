import SwiftUI

/// P-AI color tokens — map 1:1 từ tokens/colors.css.
/// Purple as the new neutral: royal purple primary, lavender tints làm surface.
enum PAIColor {
    // MARK: Brand purple scale
    static let purple50  = Color(hex: 0xF5F3FF)
    static let purple100 = Color(hex: 0xEDE9FE)  // lavender surface tint
    static let purple200 = Color(hex: 0xDDD6FE)
    static let purple300 = Color(hex: 0xC4B5FD)
    static let purple400 = Color(hex: 0xA78BFA)
    static let purple500 = Color(hex: 0x8B5CF6)  // violet accent
    static let purple600 = Color(hex: 0x7C3AED)
    static let purple700 = Color(hex: 0x6D28D9)
    static let purple800 = Color(hex: 0x5B21B6)  // royal-purple primary
    static let purple900 = Color(hex: 0x4C1D95)
    static let purple950 = Color(hex: 0x2E1065)

    // MARK: Warm purple-tinted neutrals
    static let neutral0   = Color(hex: 0xFFFFFF)
    static let neutral50  = Color(hex: 0xFAF9FC)  // warm off-white paper
    static let neutral100 = Color(hex: 0xF3F1F8)
    static let neutral200 = Color(hex: 0xE9E6F0)
    static let neutral300 = Color(hex: 0xD6D1E0)
    static let neutral400 = Color(hex: 0xA8A1B8)
    static let neutral500 = Color(hex: 0x79728C)
    static let neutral800 = Color(hex: 0x2A2438)
    static let neutral900 = Color(hex: 0x1A1625)  // near-black ink

    // MARK: Semantic aliases — components dùng các alias này
    static let brand        = purple800
    static let brandHover   = purple900
    static let brandAccent  = purple500
    static let brandSubtle  = purple100
    static let onBrand      = neutral0

    static let textStrong   = neutral900
    static let textBody     = neutral800
    static let textMuted    = neutral500
    static let textBrand    = purple700

    static let surfacePage  = neutral50
    static let surfaceCard  = neutral0
    static let surfaceTint  = purple100

    static let borderHairline = Color(hex: 0x5B21B6, opacity: 0.10)
    static let ring           = purple500

    static let success = Color(hex: 0x16A34A)
    static let warning = Color(hex: 0xD97706)
    static let danger  = Color(hex: 0xDC2626)

    // MARK: Gradient stops — chỉ dùng cho AI/generative moments
    static let gradFrom = purple700
    static let gradVia  = purple500
    static let gradTo   = Color(hex: 0xC026D3)  // fuchsia kicker
}
