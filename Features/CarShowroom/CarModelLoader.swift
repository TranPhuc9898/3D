import RealityKit

/// Cache model xe: USDZ ~145k tam giác parse mất 1–3s, nên chỉ load đúng
/// một lần (preload ngầm lúc app khởi động), các view lấy bản clone —
/// clone dùng chung mesh/texture nên tức thì và không tốn thêm RAM.
@MainActor
enum CarModelLoader {
    private static var loadTask: Task<Entity?, Never>?

    /// Gọi sớm lúc app launch để model sẵn sàng trước khi user mở showroom.
    static func preload() {
        guard loadTask == nil else { return }
        loadTask = Task {
            try? await Entity(named: "car_model")
        }
    }

    /// Bản clone của model để view tự scale/sơn màu mà không đụng bản gốc.
    /// Nếu preload chưa xong thì chờ chính task đó — không load lần hai.
    static func loadCar() async -> Entity? {
        preload()
        guard let base = await loadTask?.value else { return nil }
        return base.clone(recursive: true)
    }
}
