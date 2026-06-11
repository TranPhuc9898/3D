import SwiftUI

/// Frosted chip: icon trong ô vuông bo góc nền brand hue + label sentence case.
struct PAIChip: View {
    let icon: String
    let title: String
    var action: () -> Void = {}

    var body: some View {
        Button(action: action) {
            HStack(spacing: PAISpace.s3) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(PAIColor.onBrand)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: PAIRadius.md, style: .continuous)
                            .fill(PAIColor.brandAccent)
                    )
                Text(title)
                    .font(PAIFont.sm)
                    .foregroundStyle(PAIColor.textBody)
            }
            .padding(.horizontal, PAISpace.s4)
            .padding(.vertical, PAISpace.s3)
            .background(
                RoundedRectangle(cornerRadius: PAIRadius.lg, style: .continuous)
                    .fill(.white.opacity(0.75))
            )
            .overlay(
                RoundedRectangle(cornerRadius: PAIRadius.lg, style: .continuous)
                    .stroke(PAIColor.borderHairline, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
