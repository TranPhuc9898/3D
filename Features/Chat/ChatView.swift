import SwiftUI

struct ChatView: View {
    @State private var viewModel = ChatViewModel()

    var body: some View {
        ZStack {
            PAIColor.surfacePage.ignoresSafeArea()

            ScrollView {
                VStack(spacing: PAISpace.s4) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal, PAISpace.s5)
                .padding(.vertical, PAISpace.s6)
            }
        }
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: PAISpace.s2) {
                Text("\(viewModel.credits) remaining credits")
                    .font(PAIFont.xs)
                    .foregroundStyle(PAIColor.textMuted)
                PAIComposer(text: $viewModel.draft) {
                    viewModel.send()
                }
            }
            .padding(.horizontal, PAISpace.s5)
            .padding(.bottom, PAISpace.s2)
        }
        .navigationTitle("P-AI")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: PAISpace.s2) {
            if message.role == .assistant {
                PAIAvatarOrb(size: 28)
            } else {
                Spacer(minLength: PAISpace.s12)
            }

            Text(message.text)
                .font(PAIFont.body)
                .foregroundStyle(message.role == .user ? PAIColor.onBrand : PAIColor.textBody)
                .padding(.horizontal, PAISpace.s4)
                .padding(.vertical, PAISpace.s3)
                .background(
                    RoundedRectangle(cornerRadius: PAIRadius.xl, style: .continuous)
                        .fill(message.role == .user ? PAIColor.brand : PAIColor.surfaceCard)
                )
                .paiShadowSoft()

            if message.role == .assistant {
                Spacer(minLength: PAISpace.s12)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
}

#Preview {
    NavigationStack {
        ChatView()
    }
}
