import SwiftUI

/// Avatar orb gradient violet→fuchsia — chỉ dành cho AI/generative moments.
struct PAIAvatarOrb: View {
    var size: CGFloat = 36

    var body: some View {
        Circle()
            .fill(PAIGradient.ai)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}
