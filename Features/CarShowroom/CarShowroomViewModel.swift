import SwiftUI
import UIKit
import RealityKit

/// Một màu sơn xe: swatch hiển thị trên UI + tint áp lên material 3D.
struct CarPaint: Identifiable, Equatable {
    let id: String
    let name: String
    let swatch: Color
    let tint: UIColor
}

@Observable
final class CarShowroomViewModel {
    // Tint trắng = giữ nguyên texture gốc (nhân màu identity).
    let paints: [CarPaint] = [
        CarPaint(id: "white", name: "Trắng Brahminy", swatch: .white, tint: .white),
        CarPaint(id: "red", name: "Đỏ Crimson", swatch: Color(hex: 0xC0252C), tint: UIColor(red: 0.75, green: 0.15, blue: 0.17, alpha: 1)),
        CarPaint(id: "yellow", name: "Vàng Summer", swatch: Color(hex: 0xF2C200), tint: UIColor(red: 0.95, green: 0.76, blue: 0.0, alpha: 1)),
        CarPaint(id: "green", name: "Xanh Iris", swatch: Color(hex: 0x2E7D5B), tint: UIColor(red: 0.18, green: 0.49, blue: 0.36, alpha: 1)),
        CarPaint(id: "pink", name: "Hồng Rose", swatch: Color(hex: 0xE8A0B4), tint: UIColor(red: 0.91, green: 0.63, blue: 0.71, alpha: 1)),
    ]

    var selectedPaint: CarPaint
    @ObservationIgnored var carEntity: Entity?

    let specs: [(label: String, value: String)] = [
        ("Quãng đường", "210 km"),
        ("Công suất", "32 kW"),
        ("Chỗ ngồi", "4 chỗ"),
        ("Sạc nhanh", "36 phút"),
    ]
    let priceText = "299.000.000 ₫"

    init() {
        selectedPaint = paints[0]
    }

    /// Scale model về kích thước chuẩn ~0.5m và đưa tâm về gốc toạ độ
    /// để orbit camera xoay quanh đúng giữa xe.
    func prepareForViewing(_ entity: Entity) -> Entity {
        let bounds = entity.visualBounds(relativeTo: nil)
        let extents = bounds.extents
        let maxDimension = max(extents.x, max(extents.y, extents.z))
        if maxDimension > 0 {
            let scale = 0.5 / maxDimension
            entity.scale *= SIMD3<Float>(repeating: scale)
            let center = bounds.center
            entity.position = [-center.x * scale, -center.y * scale, -center.z * scale]
        }
        carEntity = entity
        return entity
    }

    /// Scale xe về kích thước thật (~3.2m chiều dài VF3) và hạ gầm chạm sàn —
    /// trong AR, đơn vị của entity là mét ngoài đời thật.
    func prepareForAR(_ entity: Entity) -> Entity {
        let bounds = entity.visualBounds(relativeTo: nil)
        let extents = bounds.extents
        let maxDimension = max(extents.x, max(extents.y, extents.z))
        if maxDimension > 0 {
            let scale = 3.2 / maxDimension
            entity.scale *= SIMD3<Float>(repeating: scale)
            entity.position = [0, -bounds.min.y * scale, 0]
        }
        return entity
    }

    func applySelectedPaint() {
        guard let carEntity else { return }
        applyPaint(to: carEntity)
    }

    func applyPaint(to entity: Entity) {
        apply(tint: selectedPaint.tint, to: entity)
    }

    /// Tint toàn bộ material PBR của model. Với model VF3 thật,
    /// lọc theo tên material thân xe để không nhuộm bánh/kính.
    private func apply(tint: UIColor, to entity: Entity) {
        if var model = entity.components[ModelComponent.self] {
            model.materials = model.materials.map { material in
                guard var pbr = material as? PhysicallyBasedMaterial else { return material }
                pbr.baseColor.tint = tint
                return pbr
            }
            entity.components.set(model)
        }
        for child in entity.children {
            apply(tint: tint, to: child)
        }
    }
}
