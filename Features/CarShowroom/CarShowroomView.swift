import SwiftUI
import RealityKit

/// Showroom 3D: xoay/zoom xe bằng orbit camera, đổi màu sơn,
/// xem AR ngoài đời thật và đặt cọc (demo).
struct CarShowroomView: View {
    @State private var viewModel = CarShowroomViewModel()
    @State private var showDepositAlert = false
    @State private var showARShowroom = false

    var body: some View {
        ZStack {
            PAIGradient.page.ignoresSafeArea()

            VStack(spacing: 0) {
                // Gỡ RealityView camera ảo khi AR đang mở — hai render session
                // cùng sống làm camera feed đen (FB14731139).
                if showARShowroom {
                    Color.clear.frame(maxHeight: .infinity)
                } else {
                    carViewer
                }
                infoPanel
            }

            // Nhúng AR trực tiếp vào ZStack — present qua fullScreenCover /
            // NavigationStack làm camera feed đen dù tracking vẫn chạy.
            if showARShowroom {
                CarARShowroomView(viewModel: viewModel) {
                    showARShowroom = false
                }
                .ignoresSafeArea()
            }
        }
        .navigationTitle("VinFast VF3")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(showARShowroom ? .hidden : .visible, for: .navigationBar)
        .alert("Đặt cọc thành công (demo)", isPresented: $showDepositAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Tư vấn viên VinFast sẽ liên hệ anh trong 24h.")
        }
    }

    // MARK: - 3D viewer

    private var carViewer: some View {
        CarViewerContainer(viewModel: viewModel, selectedPaint: viewModel.selectedPaint)
            .frame(maxHeight: .infinity)
            .overlay(alignment: .bottom) {
                Text("Kéo để xoay • Chụm để thu phóng")
                    .font(PAIFont.xs)
                    .foregroundStyle(PAIColor.textMuted)
                    .padding(.bottom, PAISpace.s2)
            }
    }

    // MARK: - Info panel

    private var infoPanel: some View {
        VStack(alignment: .leading, spacing: PAISpace.s4) {
            paintPicker
            specsGrid
            actionBar
        }
        .padding(.horizontal, PAISpace.s5)
        .padding(.top, PAISpace.s4)
        .padding(.bottom, PAISpace.s5)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28)
                .fill(PAIColor.surfaceCard)
                .ignoresSafeArea(edges: .bottom)
        )
        .paiShadowSoft()
    }

    private var paintPicker: some View {
        VStack(alignment: .leading, spacing: PAISpace.s2) {
            HStack {
                PAIEyebrow(text: "Màu xe")
                Spacer()
                Text(viewModel.selectedPaint.name)
                    .font(PAIFont.sm)
                    .foregroundStyle(PAIColor.textBody)
            }
            HStack(spacing: PAISpace.s3) {
                ForEach(viewModel.paints) { paint in
                    Button {
                        viewModel.selectedPaint = paint
                    } label: {
                        Circle()
                            .fill(paint.swatch)
                            .frame(width: 36, height: 36)
                            .overlay(Circle().stroke(PAIColor.borderHairline, lineWidth: 1))
                            .overlay(
                                Circle()
                                    .stroke(PAIColor.ring, lineWidth: 2.5)
                                    .padding(-4)
                                    .opacity(viewModel.selectedPaint == paint ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var specsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: PAISpace.s3) {
            ForEach(viewModel.specs, id: \.label) { spec in
                HStack {
                    Text(spec.label)
                        .font(PAIFont.sm)
                        .foregroundStyle(PAIColor.textMuted)
                    Spacer()
                    Text(spec.value)
                        .font(PAIFont.sm.weight(.semibold))
                        .foregroundStyle(PAIColor.textStrong)
                }
                .padding(.horizontal, PAISpace.s3)
                .padding(.vertical, PAISpace.s3)
                .background(
                    RoundedRectangle(cornerRadius: PAIRadius.md, style: .continuous)
                        .fill(PAIColor.surfaceTint.opacity(0.5))
                )
            }
        }
    }

    private var actionBar: some View {
        HStack(spacing: PAISpace.s3) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Giá từ")
                    .font(PAIFont.xs)
                    .foregroundStyle(PAIColor.textMuted)
                Text(viewModel.priceText)
                    .font(PAIFont.h3)
                    .foregroundStyle(PAIColor.textStrong)
            }
            Spacer()
            Button {
                showARShowroom = true
            } label: {
                Image(systemName: "arkit")
                    .font(.system(size: 22, weight: .medium))
            }
            .buttonStyle(PAIGhostButtonStyle())
            Button("Đặt cọc") {
                showDepositAlert = true
            }
            .buttonStyle(PAIPrimaryButtonStyle())
        }
    }
}

// MARK: - Viewer 3D (ARView nonAR)

/// Viewer xoay xe bằng ARView chế độ nonAR thay cho RealityView —
/// app từng chạy RealityView là mọi màn AR sau bị mất camera feed
/// (bug renderer, Apple forum #749456). Kéo = xoay xe, chụm = thu phóng.
private struct CarViewerContainer: UIViewRepresentable {
    let viewModel: CarShowroomViewModel
    /// Đọc trong body của view cha để SwiftUI gọi updateUIView khi đổi màu.
    let selectedPaint: CarPaint

    final class Coordinator: NSObject {
        var carEntity: Entity?
        var initialScale: SIMD3<Float>?

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard let carEntity else { return }
            let translation = gesture.translation(in: gesture.view)
            let angle = Float(translation.x) * 0.01
            carEntity.orientation = simd_quatf(angle: angle, axis: [0, 1, 0]) * carEntity.orientation
            gesture.setTranslation(.zero, in: gesture.view)
        }

        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard let carEntity, let initialScale else { return }
            let ratio = carEntity.scale.x * Float(gesture.scale) / initialScale.x
            let clamped = min(max(ratio, 0.5), 3.0)
            carEntity.scale = initialScale * clamped
            gesture.scale = 1
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero, cameraMode: .nonAR, automaticallyConfigureSession: false)
        arView.environment.background = .color(UIColor.systemGray6)

        let camera = PerspectiveCamera()
        camera.look(at: .zero, from: [0.55, 0.3, 0.8], relativeTo: nil)
        let cameraAnchor = AnchorEntity(world: .zero)
        cameraAnchor.addChild(camera)
        arView.scene.addAnchor(cameraAnchor)

        let keyLight = DirectionalLight()
        keyLight.light.intensity = 3000
        keyLight.look(at: .zero, from: [1, 1.5, 1.5], relativeTo: nil)
        let fillLight = DirectionalLight()
        fillLight.light.intensity = 1200
        fillLight.look(at: .zero, from: [-1.5, 0.8, -1], relativeTo: nil)
        let lightAnchor = AnchorEntity(world: .zero)
        lightAnchor.addChild(keyLight)
        lightAnchor.addChild(fillLight)
        arView.scene.addAnchor(lightAnchor)

        let coordinator = context.coordinator
        arView.addGestureRecognizer(
            UIPanGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePan))
        )
        arView.addGestureRecognizer(
            UIPinchGestureRecognizer(target: coordinator, action: #selector(Coordinator.handlePinch))
        )

        Task { @MainActor in
            guard let car = try? await Entity(named: "car_model") else { return }
            let prepared = viewModel.prepareForViewing(car)
            let carAnchor = AnchorEntity(world: .zero)
            carAnchor.addChild(prepared)
            arView.scene.addAnchor(carAnchor)
            coordinator.carEntity = prepared
            coordinator.initialScale = prepared.scale
            viewModel.applyPaint(to: prepared)
        }
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        if let carEntity = context.coordinator.carEntity {
            viewModel.applyPaint(to: carEntity)
        }
    }
}

#Preview {
    NavigationStack {
        CarShowroomView()
    }
}
