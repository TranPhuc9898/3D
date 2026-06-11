import SwiftUI

/// Primary: pill royal-purple + brand glow, press scale 0.97.
struct PAIPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PAIFont.lg)
            .foregroundStyle(PAIColor.onBrand)
            .padding(.horizontal, PAISpace.s6)
            .padding(.vertical, PAISpace.s4)
            .background(
                Capsule().fill(configuration.isPressed ? PAIColor.brandHover : PAIColor.brand)
            )
            .paiShadowBrand()
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: PAIDuration.fast), value: configuration.isPressed)
    }
}

/// Ghost: tint wash violet khi press, không nền mặc định.
struct PAIGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(PAIFont.body)
            .foregroundStyle(PAIColor.textBrand)
            .padding(.horizontal, PAISpace.s4)
            .padding(.vertical, PAISpace.s2)
            .background(
                Capsule().fill(
                    configuration.isPressed
                        ? PAIColor.purple500.opacity(0.12)
                        : .clear
                )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: PAIDuration.fast), value: configuration.isPressed)
    }
}
