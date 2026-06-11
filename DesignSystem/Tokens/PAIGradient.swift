import SwiftUI

/// Gradient violet → fuchsia — CHỈ dùng cho AI/generative moments
/// (avatar orbs, hero glows), không dùng trên text body hay surface chức năng.
enum PAIGradient {
    static let ai = LinearGradient(
        colors: [PAIColor.gradFrom, PAIColor.gradVia, PAIColor.gradTo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Nền page light mode: lavender → paper dọc.
    static let page = LinearGradient(
        colors: [PAIColor.purple100, PAIColor.surfacePage],
        startPoint: .top,
        endPoint: .bottom
    )
}
