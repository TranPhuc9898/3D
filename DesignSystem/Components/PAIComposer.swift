import SwiftUI

/// Composer pill: input + nút send tròn brand (icon ↑ filled là ngoại lệ duy nhất).
struct PAIComposer: View {
    @Binding var text: String
    let onSend: () -> Void

    var body: some View {
        HStack(spacing: PAISpace.s3) {
            TextField("Type to start a new chat…", text: $text)
                .font(PAIFont.body)
                .foregroundStyle(PAIColor.textBody)

            Button(action: onSend) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PAIColor.onBrand)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(PAIColor.brand))
            }
            .buttonStyle(.plain)
            .disabled(text.isEmpty)
            .opacity(text.isEmpty ? 0.4 : 1)
        }
        .padding(.leading, PAISpace.s5)
        .padding(.trailing, PAISpace.s2)
        .padding(.vertical, PAISpace.s2)
        .background(
            RoundedRectangle(cornerRadius: PAIRadius.composer, style: .continuous)
                .fill(PAIColor.surfaceCard)
        )
        .paiShadowSoft()
    }
}
