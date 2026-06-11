import SwiftUI

/// Card P-AI: nền trắng, radius lớn, shadow tím mềm, không border.
struct PAICard<Content: View>: View {
    var radius: CGFloat = PAIRadius.lg
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(PAISpace.s4)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(PAIColor.surfaceCard)
            )
            .paiShadowSoft()
    }
}
