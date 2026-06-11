import SwiftUI

enum AppRoute: Hashable {
    case chat
    case settings
    case carShowroom
}

@Observable
final class AppRouter {
    var path = NavigationPath()

    func push(_ route: AppRoute) {
        path.append(route)
    }

    func pop() {
        path.removeLast()
    }
}
