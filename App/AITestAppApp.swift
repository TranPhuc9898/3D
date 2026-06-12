import SwiftUI

@main
struct AITestAppApp: App {
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .chat:
                            ChatView()
                        case .settings:
                            SettingsView()
                        case .carShowroom:
                            CarShowroomView()
                        }
                    }
            }
            .environment(router)
            // Load ngầm model xe (~1-3s) ngay từ lúc mở app — vào showroom là xe hiện liền.
            .task { CarModelLoader.preload() }
        }
    }
}
