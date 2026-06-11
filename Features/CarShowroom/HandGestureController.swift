import ARKit
import Vision

/// Cử chỉ tay đang active — UI dùng để hiện hướng dẫn tương ứng.
enum HandGesture {
    case rotate   // 🤏 chụm cái+trỏ, di ngang
    case scale    // 🖐↔🤌 banh / chụm cả bàn tay
    case move     // ✊ nắm đấm, di tay
}

/// Nhận diện 3 cử chỉ tay qua camera bằng Vision (21 landmarks, rule thuần
/// hình học — không cần model ML): chụm cái+trỏ + di ngang = xoay,
/// banh/chụm cả bàn tay = phóng to/thu nhỏ, nắm đấm + di = di chuyển xe.
/// Đọc ké frame từ ARSession đang chạy — không mở camera session mới.
/// Mỗi pose phải giữ ổn định 3 frame mới kích hoạt (chống nhận nhầm lúc
/// tay đang biến hình giữa các pose).
final class HandGestureController: NSObject, ARSessionDelegate {
    /// Góc xoay (radian) mỗi nhịp tay di ngang — bắn trên main thread.
    var onRotate: ((Float) -> Void)?
    /// Hệ số scale mỗi nhịp (nhân dồn), đã chặn spike trong 0.9–1.1.
    var onScale: ((Float) -> Void)?
    /// Delta di chuyển chuẩn hoá theo khung hình: (ngang, xa/gần).
    var onMove: ((Float, Float) -> Void)?
    /// Cử chỉ active thay đổi (nil = không có tay / không pose nào).
    var onGestureChanged: ((HandGesture?) -> Void)?

    private let request: VNDetectHumanHandPoseRequest = {
        let request = VNDetectHumanHandPoseRequest()
        request.maximumHandCount = 1
        return request
    }()
    private let visionQueue = DispatchQueue(label: "hand-gesture-vision")
    private var isProcessing = false
    private var lastSampleTime: TimeInterval = 0

    private var activePose: RawPose = .none
    private var candidatePose: RawPose = .none
    private var candidateCount = 0
    private var missingFrames = 0

    private var lastHandX: CGFloat?
    private var lastSpread: CGFloat?
    private var lastPalmPoint: CGPoint?

    /// Tay quét hết chiều ngang khung hình = xoay 180°.
    private let radiansPerFullSweep: Float = .pi

    // MARK: - ARSessionDelegate

    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // ~15 mẫu/giây là đủ mượt cho cử chỉ, đỡ chiếm Neural Engine.
        guard frame.timestamp - lastSampleTime > 1.0 / 15.0, !isProcessing else { return }
        lastSampleTime = frame.timestamp
        isProcessing = true
        let pixelBuffer = frame.capturedImage
        visionQueue.async { [weak self] in
            self?.process(pixelBuffer)
            self?.isProcessing = false
        }
    }

    // MARK: - Vision

    private func process(_ pixelBuffer: CVPixelBuffer) {
        // Buffer camera là landscape sensor-native; .right xoay về portrait
        // để trục x của landmark trùng chiều ngang màn hình.
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .right)
        try? handler.perform([request])

        guard let hand = request.results?.first,
              let joints = try? hand.recognizedPoints(.all),
              let sample = HandSample(joints: joints) else {
            registerMissingHand()
            return
        }
        missingFrames = 0
        advance(with: sample)
    }

    /// Vision hay rớt tay vài frame — chỉ coi là mất tay khi vắng 5 frame liền.
    private func registerMissingHand() {
        missingFrames += 1
        guard missingFrames == 5, activePose != .none else { return }
        activePose = .none
        candidatePose = .none
        candidateCount = 0
        clearTracking()
        DispatchQueue.main.async { self.onGestureChanged?(nil) }
    }

    private func advance(with sample: HandSample) {
        if sample.rawPose == activePose {
            candidateCount = 0
            track(sample)
            return
        }
        // Pose mới phải giữ ổn định 3 frame mới chuyển — trong lúc chờ thì
        // đứng yên, tránh "chụm tay thành nắm đấm" bị hiểu nhầm là thu nhỏ.
        if sample.rawPose == candidatePose {
            candidateCount += 1
        } else {
            candidatePose = sample.rawPose
            candidateCount = 1
        }
        guard candidateCount >= 3 else { return }
        activePose = sample.rawPose
        candidateCount = 0
        clearTracking()
        track(sample)
        let gesture: HandGesture? = switch activePose {
        case .pinch: .rotate
        case .palm: .scale
        case .fist: .move
        case .none: nil
        }
        DispatchQueue.main.async { self.onGestureChanged?(gesture) }
    }

    private func track(_ sample: HandSample) {
        switch activePose {
        case .pinch:
            if let lastX = lastHandX {
                let deltaX = Float(sample.wristX - lastX)
                if abs(deltaX) > 0.002 {
                    let angle = deltaX * radiansPerFullSweep
                    DispatchQueue.main.async { self.onRotate?(angle) }
                }
            }
            lastHandX = sample.wristX
        case .palm:
            if let lastSpread, lastSpread > 0.01 {
                let ratio = min(max(Float(sample.spread / lastSpread), 0.9), 1.1)
                if abs(ratio - 1) > 0.005 {
                    DispatchQueue.main.async { self.onScale?(ratio) }
                }
            }
            lastSpread = sample.spread
        case .fist:
            if let lastPoint = lastPalmPoint {
                let dx = Float(sample.palmPoint.x - lastPoint.x)
                let dz = Float(sample.palmPoint.y - lastPoint.y)
                if abs(dx) > 0.002 || abs(dz) > 0.002 {
                    DispatchQueue.main.async { self.onMove?(dx, dz) }
                }
            }
            lastPalmPoint = sample.palmPoint
        case .none:
            break
        }
    }

    private func clearTracking() {
        lastHandX = nil
        lastSpread = nil
        lastPalmPoint = nil
    }
}

private enum RawPose {
    case pinch, palm, fist, none
}

// MARK: - Hình học bàn tay

/// Trích số liệu hình học từ 21 landmarks: mọi khoảng cách đều chia cho
/// cỡ bàn tay (cổ tay → khớp gốc ngón giữa) để bất biến với khoảng cách
/// tay–camera.
private struct HandSample {
    let wristX: CGFloat
    let palmPoint: CGPoint
    let spread: CGFloat
    let rawPose: RawPose

    init?(joints: [VNHumanHandPoseObservation.JointName: VNRecognizedPoint]) {
        func point(_ name: VNHumanHandPoseObservation.JointName) -> CGPoint? {
            guard let recognized = joints[name], recognized.confidence > 0.3 else { return nil }
            return recognized.location
        }
        guard let wrist = point(.wrist),
              let thumbTip = point(.thumbTip),
              let indexTip = point(.indexTip),
              let middleTip = point(.middleTip),
              let ringTip = point(.ringTip),
              let littleTip = point(.littleTip),
              let indexMCP = point(.indexMCP),
              let middleMCP = point(.middleMCP),
              let ringMCP = point(.ringMCP),
              let littleMCP = point(.littleMCP)
        else { return nil }

        func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
            hypot(a.x - b.x, a.y - b.y)
        }

        let handSize = distance(wrist, middleMCP)
        guard handSize > 0.01 else { return nil }

        let palmCenter = CGPoint(
            x: (indexMCP.x + middleMCP.x + ringMCP.x + littleMCP.x) / 4,
            y: (indexMCP.y + middleMCP.y + ringMCP.y + littleMCP.y) / 4
        )
        let tips = [thumbTip, indexTip, middleTip, ringTip, littleTip]
        // Độ duỗi từng ngón (trừ cái): đầu ngón cách tâm lòng bàn tay bao xa.
        let fingerCurls = [indexTip, middleTip, ringTip, littleTip]
            .map { distance($0, palmCenter) / handSize }
        let pinchDistance = distance(thumbTip, indexTip) / handSize

        wristX = wrist.x
        palmPoint = palmCenter
        spread = tips.map { distance($0, palmCenter) / handSize }
            .reduce(0, +) / CGFloat(tips.count)

        if fingerCurls.allSatisfy({ $0 < 0.6 }) {
            rawPose = .fist
        } else if pinchDistance < 0.4, fingerCurls[1] > 0.8 {
            // Cái+trỏ chạm nhau, ngón giữa vẫn duỗi → pinch chứ không phải chụm cả tay.
            rawPose = .pinch
        } else if fingerCurls.allSatisfy({ $0 > 0.7 }), pinchDistance > 0.5 {
            rawPose = .palm
        } else {
            rawPose = .none
        }
    }
}
