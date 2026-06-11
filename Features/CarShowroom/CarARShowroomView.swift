import SwiftUI
import RealityKit
import ARKit

/// AR showroom: camera thật, xe đặt trên sàn nhà bằng plane anchor,
/// overlay đổi màu + đặt cọc ngay trong lúc ngắm xe.
/// Dùng ARView (UIKit) thay RealityView .spatialTracking — RealityView
/// bị bug camera đen khi present qua fullScreenCover (FB14731139).
struct CarARShowroomView: View {
    let viewModel: CarShowroomViewModel
    /// Đóng màn AR — view được nhúng thẳng vào ZStack (không dùng
    /// fullScreenCover vì presentation làm camera feed đen).
    let onClose: () -> Void

    @State private var showDepositAlert = false
    @State private var activeGesture: HandGesture?

    var body: some View {
        ZStack {
            ARCarContainer(
                viewModel: viewModel,
                selectedPaint: viewModel.selectedPaint,
                onHandGesture: { activeGesture = $0 }
            )
            .ignoresSafeArea()
            overlayControls
        }
        .alert("Đặt cọc thành công (demo)", isPresented: $showDepositAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Tư vấn viên VinFast sẽ liên hệ anh trong 24h.")
        }
    }

    // MARK: - Overlay

    private var overlayControls: some View {
        VStack {
            HStack {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(.black.opacity(0.4), in: Circle())
                }
                Spacer()
            }
            .padding(.horizontal, PAISpace.s5)

            if let activeGesture {
                Label(activeGesture.hint, systemImage: activeGesture.icon)
                    .font(PAIFont.xs)
                    .foregroundStyle(.white)
                    .padding(.horizontal, PAISpace.s4)
                    .padding(.vertical, PAISpace.s2)
                    .background(.black.opacity(0.4), in: Capsule())
            }

            Spacer()

            bottomPanel
        }
        .padding(.vertical, PAISpace.s4)
        .animation(.easeInOut(duration: 0.2), value: activeGesture)
    }

    private var bottomPanel: some View {
        VStack(spacing: PAISpace.s3) {
            HStack(spacing: PAISpace.s3) {
                ForEach(viewModel.paints) { paint in
                    Button {
                        viewModel.selectedPaint = paint
                    } label: {
                        Circle()
                            .fill(paint.swatch)
                            .frame(width: 34, height: 34)
                            .overlay(
                                Circle()
                                    .stroke(.white, lineWidth: 2.5)
                                    .padding(-4)
                                    .opacity(viewModel.selectedPaint == paint ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: PAISpace.s3) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("VinFast VF3 • \(viewModel.selectedPaint.name)")
                        .font(PAIFont.xs)
                        .foregroundStyle(.white.opacity(0.8))
                    Text(viewModel.priceText)
                        .font(PAIFont.h3)
                        .foregroundStyle(.white)
                }
                Spacer()
                Button("Đặt cọc") {
                    showDepositAlert = true
                }
                .buttonStyle(PAIPrimaryButtonStyle())
            }
        }
        .padding(PAISpace.s4)
        .background(
            RoundedRectangle(cornerRadius: PAIRadius.lg, style: .continuous)
                .fill(.black.opacity(0.45))
        )
        .padding(.horizontal, PAISpace.s5)
    }
}

// MARK: - Hint cử chỉ

private extension HandGesture {
    var hint: String {
        switch self {
        case .rotate: "Đang xoay — di tay ngang"
        case .scale: "Banh tay phóng to, chụm lại thu nhỏ"
        case .move: "Đang di chuyển — di tay tới chỗ muốn đặt xe"
        }
    }

    var icon: String {
        switch self {
        case .rotate: "arrow.triangle.2.circlepath"
        case .scale: "plus.magnifyingglass"
        case .move: "arrow.up.and.down.and.arrow.left.and.right"
        }
    }
}

// MARK: - ARView wrapper

/// ARView chạy world tracking + plane detection: camera feed làm nền,
/// xe gắn vào sàn thật, gesture chụm = zoom, xoay 2 ngón = xoay xe.
private struct ARCarContainer: UIViewRepresentable {
    let viewModel: CarShowroomViewModel
    /// Đọc trong body của view cha để SwiftUI gọi updateUIView khi đổi màu.
    let selectedPaint: CarPaint
    /// Báo lên SwiftUI cử chỉ tay đang active (hiện indicator hướng dẫn).
    let onHandGesture: (HandGesture?) -> Void

    final class Coordinator {
        var carEntity: Entity?
        var holderEntity: ModelEntity?
        let handGesture = HandGestureController()
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)
        arView.environment.background = .cameraFeed()

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        // Probe môi trường thật để sơn xe (PBR) phản chiếu không gian xung quanh.
        configuration.environmentTexturing = .automatic
        // Người đi qua trước xe sẽ che xe (cần chip A12+).
        if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
            configuration.frameSemantics.insert(.personSegmentationWithDepth)
        }
        arView.session.run(configuration)

        let coachingOverlay = ARCoachingOverlayView()
        coachingOverlay.session = arView.session
        coachingOverlay.goal = .horizontalPlane
        coachingOverlay.frame = arView.bounds
        coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        arView.addSubview(coachingOverlay)

        // .any + bounds nhỏ: sàn lẫn mặt bàn đều đặt được — classification
        // .floor ≥ 0.5m từng làm anchor không bao giờ kích hoạt ở phòng hẹp.
        let floorAnchor = AnchorEntity(
            .plane(.horizontal, classification: .any, minimumBounds: [0.3, 0.3])
        )
        arView.scene.addAnchor(floorAnchor)

        let coordinator = context.coordinator

        // Tay trước camera: chụm cái+trỏ = xoay, banh/chụm cả tay = scale,
        // nắm đấm + di = di chuyển xe trên sàn.
        arView.session.delegate = coordinator.handGesture
        coordinator.handGesture.onGestureChanged = onHandGesture
        coordinator.handGesture.onRotate = { [weak coordinator] angle in
            guard let holder = coordinator?.holderEntity else { return }
            holder.transform.rotation =
                simd_quatf(angle: angle, axis: [0, 1, 0]) * holder.transform.rotation
        }
        coordinator.handGesture.onScale = { [weak coordinator] ratio in
            guard let holder = coordinator?.holderEntity else { return }
            // Clamp 0.5×–2× để xe không thành đồ chơi hay quái vật.
            let target = min(max(holder.scale.x * ratio, 0.5), 2.0)
            holder.scale = SIMD3<Float>(repeating: target)
        }
        coordinator.handGesture.onMove = { [weak coordinator, weak arView] dx, dz in
            guard let holder = coordinator?.holderEntity, let arView else { return }
            // Trượt xe theo hướng nhìn: tay phải = xe sang phải theo góc
            // nhìn, tay lên = xe ra xa. Chiếu vector camera lên mặt sàn.
            let cam = arView.cameraTransform.matrix
            var right = SIMD3<Float>(cam.columns.0.x, 0, cam.columns.0.z)
            var forward = SIMD3<Float>(-cam.columns.2.x, 0, -cam.columns.2.z)
            guard simd_length(right) > 0.001, simd_length(forward) > 0.001 else { return }
            right = simd_normalize(right)
            forward = simd_normalize(forward)
            // Tay quét hết khung hình = xe dịch ~2m.
            let worldDelta = right * (dx * 2.0) + forward * (dz * 2.0)
            let localDelta = holder.parent.map {
                $0.convert(direction: worldDelta, from: nil)
            } ?? worldDelta
            holder.position += localDelta
        }

        Task { @MainActor in
            guard let car = try? await Entity(named: "car_model") else { return }
            let prepared = viewModel.prepareForAR(car)
            applyGroundingShadow(to: prepared)

            // Holder có khối va chạm bao trọn xe để installGestures nhận touch.
            let holder = ModelEntity()
            holder.addChild(prepared)
            let bounds = prepared.visualBounds(relativeTo: holder)
            holder.collision = CollisionComponent(shapes: [
                .generateBox(size: bounds.extents).offsetBy(translation: bounds.center)
            ])

            // Animation phóng to chạy ngay không chờ event — nếu sàn chưa
            // detect xong thì xe vẫn chắc chắn hiện full-size lúc anchor bám.
            let finalTransform = holder.transform
            holder.transform.scale = SIMD3<Float>(repeating: 0.001)
            floorAnchor.addChild(holder)
            arView.installGestures([.translation, .scale, .rotation], for: holder)
            holder.move(to: finalTransform, relativeTo: floorAnchor,
                        duration: 0.6, timingFunction: .easeOut)
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            coordinator.carEntity = prepared
            coordinator.holderEntity = holder
            viewModel.applyPaint(to: prepared)
        }
        return arView
    }

    /// Bật bóng tiếp đất cho mọi mesh của xe.
    private func applyGroundingShadow(to entity: Entity) {
        if entity.components.has(ModelComponent.self) {
            entity.components.set(GroundingShadowComponent(castsShadow: true))
        }
        for child in entity.children {
            applyGroundingShadow(to: child)
        }
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let carEntity = context.coordinator.carEntity {
            viewModel.applyPaint(to: carEntity)
        }
    }

    static func dismantleUIView(_ uiView: ARView, coordinator: Coordinator) {
        uiView.session.pause()
    }
}
