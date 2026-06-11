import SwiftUI

struct HomeView: View {
    @Environment(AppRouter.self) private var router
    @State private var viewModel = HomeViewModel()
    @State private var draft = ""

    var body: some View {
        ZStack {
            PAIGradient.page.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: PAISpace.s8) {
                    header
                    featureChips
                    showroomCard
                    recentConversations
                }
                .padding(.horizontal, PAISpace.s5)
                .padding(.top, PAISpace.s6)
                .padding(.bottom, 120)
            }
        }
        .safeAreaInset(edge: .bottom) {
            PAIComposer(text: $draft) {
                draft = ""
                router.push(.chat)
            }
            .padding(.horizontal, PAISpace.s5)
            .padding(.bottom, PAISpace.s2)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: PAISpace.s2) {
            HStack {
                PAIEyebrow(text: "Good morning")
                Spacer()
                PAIAvatarOrb()
            }
            Text("Create, explore, be inspired")
                .font(PAIFont.display)
                .tracking(PAITracking.tight)
                .foregroundStyle(PAIColor.textStrong)
                .lineSpacing(2)
        }
    }

    private var featureChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: PAISpace.s3) {
                ForEach(viewModel.features, id: \.title) { feature in
                    PAIChip(icon: feature.icon, title: feature.title) {
                        router.push(.chat)
                    }
                }
            }
        }
    }

    private var showroomCard: some View {
        Button {
            router.push(.carShowroom)
        } label: {
            PAICard {
                HStack(spacing: PAISpace.s3) {
                    Image(systemName: "car.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(PAIColor.onBrand)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: PAIRadius.md, style: .continuous)
                                .fill(PAIColor.brand)
                        )
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Showroom 3D")
                            .font(PAIFont.h3)
                            .foregroundStyle(PAIColor.textStrong)
                        Text("Xem VinFast VF3, đổi màu, đặt cọc")
                            .font(PAIFont.sm)
                            .foregroundStyle(PAIColor.textMuted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(PAIColor.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
    }

    private var recentConversations: some View {
        VStack(alignment: .leading, spacing: PAISpace.s4) {
            PAIEyebrow(text: "Recent")
            ForEach(viewModel.conversations) { conversation in
                Button {
                    router.push(.chat)
                } label: {
                    PAICard {
                        VStack(alignment: .leading, spacing: PAISpace.s1) {
                            Text(conversation.title)
                                .font(PAIFont.h3)
                                .foregroundStyle(PAIColor.textStrong)
                            Text(conversation.preview)
                                .font(PAIFont.sm)
                                .foregroundStyle(PAIColor.textMuted)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .buttonStyle(.plain)
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environment(AppRouter())
}
