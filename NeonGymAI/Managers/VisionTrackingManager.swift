import AVFoundation
import Combine
import CoreGraphics
import ImageIO
import Vision

struct PosePoint: Identifiable {
    let id: String
    let location: CGPoint
    let confidence: Float
}

enum SquatPhase: String {
    case up = "UP"
    case down = "DOWN"
}

struct SquatMetrics {
    let reps: Int
    let phase: SquatPhase
    let feedback: String
}

private func visionJointKey(_ joint: VNHumanBodyPoseObservation.JointName) -> String {
    String(describing: joint)
}

/// Small, replaceable adapter for Dev1's exercise logic. It consumes the
/// normalized Vision landmarks and publishes metrics back to the tracking UI.
final class SquatRepCounter {
    private(set) var reps = 0
    private(set) var phase: SquatPhase = .up
    private var isArmed = false
    private var standingFrames = 0
    private var downFrames = 0
    private var missingPoseFrames = 0
    private var baselineLegHeight: CGFloat?
    private var baselineHipY: CGFloat?
    private var baselineHipKneeHeight: CGFloat?

    private let calibrationFrameCount = 5
    private let downFrameCount = 2
    private let poseLossFrameCount = 8

    func reset() {
        reps = 0
        resetMotion()
    }

    /// Cancels an in-progress rep after Vision loses the user's lower body.
    /// Returning to the frame must recalibrate before another rep can count.
    func poseLost() -> SquatMetrics {
        missingPoseFrames += 1
        if missingPoseFrames >= poseLossFrameCount {
            resetMotion()
            return metrics(feedback: "Pose lost - re-center and stand still")
        }
        return metrics(feedback: "Searching for your full lower body")
    }

    func update(points: [String: CGPoint]) -> SquatMetrics {
        guard let sample = squatSample(from: points) else {
            return updateFromPartialPose(points: points)
        }

        missingPoseFrames = 0
        let isStanding = sample.kneeAngle > 150
        if isStanding {
            standingFrames += 1
            downFrames = 0
            updateBaseline(hipY: sample.hipY,
                           legHeight: sample.legHeight,
                           hipKneeHeight: sample.hipKneeHeight)

            if standingFrames >= calibrationFrameCount {
                isArmed = true
            }

            if phase == .down {
                phase = .up
                if isArmed {
                    reps += 1
                }
            }

            let feedback = isArmed
                ? torsoFeedback(points: points)
                : "Stand still to calibrate your squat"
            return metrics(feedback: feedback)
        }

        standingFrames = 0
        guard isArmed, baselineLegHeight != nil else {
            return metrics(feedback: "Stand tall to calibrate before counting")
        }

        // This intentionally works from any stable camera position: front,
        // rear, profile, or diagonal. A squat needs a bent visible knee and a
        // real hip drop; walking usually does not move the hip down enough.
        let kneeBent = sample.kneeAngle < 155
        // A profile view has a smaller vertical hip movement in Vision's
        // normalized coordinates than a front view.  This is still combined
        // with a bent knee and a calibrated standing pose, so walking back
        // into frame cannot create a rep on its own.
        let hipDropped = baselineHipY.map { $0 - sample.hipY > 0.025 } ?? false
        if kneeBent && hipDropped {
            downFrames += 1
            if downFrames >= downFrameCount {
                phase = .down
            }
            return metrics(feedback: phase == .down
                           ? "Drive through your heels to stand"
                           : "Lower with control")
        }

        downFrames = 0
        return metrics(feedback: "Keep one full leg visible and lower with control")
    }

    private func resetMotion() {
        phase = .up
        isArmed = false
        standingFrames = 0
        downFrames = 0
        missingPoseFrames = 0
        baselineLegHeight = nil
        baselineHipY = nil
        baselineHipKneeHeight = nil
    }

    private func metrics(feedback: String) -> SquatMetrics {
        SquatMetrics(reps: reps, phase: phase, feedback: feedback)
    }

    private func updateBaseline(hipY: CGFloat,
                                legHeight: CGFloat,
                                hipKneeHeight: CGFloat) {
        guard legHeight > 0 else { return }
        if let baselineLegHeight {
            self.baselineLegHeight = baselineLegHeight * 0.85 + legHeight * 0.15
        } else {
            baselineLegHeight = legHeight
        }

        if let baselineHipY {
            self.baselineHipY = baselineHipY * 0.85 + hipY * 0.15
        } else {
            baselineHipY = hipY
        }

        if let baselineHipKneeHeight {
            self.baselineHipKneeHeight = baselineHipKneeHeight * 0.85 + hipKneeHeight * 0.15
        } else {
            baselineHipKneeHeight = hipKneeHeight
        }
    }

    /// Vision commonly loses an ankle for a few frames at the bottom of a
    /// profile squat. Preserve the rep only when the remaining hip and knee
    /// landmarks show both a real hip drop and a compressed upper leg. A
    /// person simply walking out of frame does not satisfy these conditions.
    private func updateFromPartialPose(points: [String: CGPoint]) -> SquatMetrics {
        guard isArmed,
              let baselineHipY,
              let baselineHipKneeHeight,
              let sample = partialSquatSample(from: points) else {
            return poseLost()
        }

        let hipDropped = baselineHipY - sample.hipY > 0.025
        let upperLegCompressed = sample.hipKneeHeight < baselineHipKneeHeight * 0.82
        guard hipDropped, upperLegCompressed else {
            return poseLost()
        }

        missingPoseFrames = 0
        standingFrames = 0
        downFrames += 1
        if downFrames >= downFrameCount {
            phase = .down
        }

        return metrics(feedback: phase == .down
                       ? "Squat depth detected - drive up"
                       : "Hold your depth for a moment")
    }

    private func torsoFeedback(points: [String: CGPoint]) -> String {
        let shoulders = midpoint(points[visionJointKey(.leftShoulder)], points[visionJointKey(.rightShoulder)])
        let hips = midpoint(points[visionJointKey(.leftHip)], points[visionJointKey(.rightHip)])
        guard let shoulders, let hips else { return "Pose locked - keep your feet visible" }

        let horizontalOffset = abs(shoulders.x - hips.x)
        let verticalDistance = max(abs(shoulders.y - hips.y), 0.001)
        let leanAngle = atan2(horizontalOffset, verticalDistance) * 180 / .pi
        return leanAngle > 25 ? "Keep your back upright" : "Good form - keep going"
    }

    private func squatSample(from points: [String: CGPoint]) -> (kneeAngle: CGFloat, hipY: CGFloat, legHeight: CGFloat, hipKneeHeight: CGFloat)? {
        let samples = [
            legSample(points: points, hip: .leftHip, knee: .leftKnee, ankle: .leftAnkle),
            legSample(points: points, hip: .rightHip, knee: .rightKnee, ankle: .rightAnkle)
        ].compactMap { $0 }

        // A profile or rear view can hide one leg. Use the most completely
        // visible leg instead of requiring left/right labels from a front view.
        return samples.max(by: { $0.legHeight < $1.legHeight })
    }

    private func legSample(points: [String: CGPoint],
                           hip: VNHumanBodyPoseObservation.JointName,
                           knee: VNHumanBodyPoseObservation.JointName,
                           ankle: VNHumanBodyPoseObservation.JointName) -> (kneeAngle: CGFloat, hipY: CGFloat, legHeight: CGFloat, hipKneeHeight: CGFloat)? {
        guard let hipPoint = points[visionJointKey(hip)],
              let kneePoint = points[visionJointKey(knee)],
              let anklePoint = points[visionJointKey(ankle)] else {
            return nil
        }

        let legHeight = abs(hipPoint.y - anklePoint.y)
        guard legHeight > 0.1 else { return nil }
        return (angle(from: hipPoint, through: kneePoint, to: anklePoint),
                hipPoint.y,
                legHeight,
                abs(hipPoint.y - kneePoint.y))
    }

    private func partialSquatSample(from points: [String: CGPoint]) -> (hipY: CGFloat, hipKneeHeight: CGFloat)? {
        let samples = [
            hipKneeSample(points: points, hip: .leftHip, knee: .leftKnee),
            hipKneeSample(points: points, hip: .rightHip, knee: .rightKnee)
        ].compactMap { $0 }

        return samples.max(by: { $0.hipKneeHeight < $1.hipKneeHeight })
    }

    private func hipKneeSample(points: [String: CGPoint],
                               hip: VNHumanBodyPoseObservation.JointName,
                               knee: VNHumanBodyPoseObservation.JointName) -> (hipY: CGFloat, hipKneeHeight: CGFloat)? {
        guard let hipPoint = points[visionJointKey(hip)],
              let kneePoint = points[visionJointKey(knee)] else {
            return nil
        }

        return (hipPoint.y, abs(hipPoint.y - kneePoint.y))
    }

    private func midpoint(_ a: CGPoint?, _ b: CGPoint?) -> CGPoint? {
        guard let a, let b else { return nil }
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private func angle(from a: CGPoint, through b: CGPoint, to c: CGPoint) -> CGFloat {
        let first = CGVector(dx: a.x - b.x, dy: a.y - b.y)
        let second = CGVector(dx: c.x - b.x, dy: c.y - b.y)
        let dot = first.dx * second.dx + first.dy * second.dy
        let magnitude = hypot(first.dx, first.dy) * hypot(second.dx, second.dy)
        guard magnitude > 0 else { return 180 }
        let cosine = max(-1, min(1, dot / magnitude))
        return acos(cosine) * 180 / .pi
    }

}

final class VisionTrackingManager: ObservableObject {
    @Published private(set) var points: [PosePoint] = []
    @Published private(set) var isTracking = false
    @Published private(set) var metrics = SquatMetrics(reps: 0, phase: .up, feedback: "Move into frame")
    @Published private(set) var errorMessage: String?

    static let skeletalConnections: [(String, String)] = [
        (String(describing: VNHumanBodyPoseObservation.JointName.leftShoulder), String(describing: VNHumanBodyPoseObservation.JointName.rightShoulder)),
        (String(describing: VNHumanBodyPoseObservation.JointName.leftShoulder), String(describing: VNHumanBodyPoseObservation.JointName.leftElbow)),
        (String(describing: VNHumanBodyPoseObservation.JointName.leftElbow), String(describing: VNHumanBodyPoseObservation.JointName.leftWrist)),
        (String(describing: VNHumanBodyPoseObservation.JointName.rightShoulder), String(describing: VNHumanBodyPoseObservation.JointName.rightElbow)),
        (String(describing: VNHumanBodyPoseObservation.JointName.rightElbow), String(describing: VNHumanBodyPoseObservation.JointName.rightWrist)),
        (String(describing: VNHumanBodyPoseObservation.JointName.leftShoulder), String(describing: VNHumanBodyPoseObservation.JointName.leftHip)),
        (String(describing: VNHumanBodyPoseObservation.JointName.rightShoulder), String(describing: VNHumanBodyPoseObservation.JointName.rightHip)),
        (String(describing: VNHumanBodyPoseObservation.JointName.leftHip), String(describing: VNHumanBodyPoseObservation.JointName.rightHip)),
        (String(describing: VNHumanBodyPoseObservation.JointName.leftHip), String(describing: VNHumanBodyPoseObservation.JointName.leftKnee)),
        (String(describing: VNHumanBodyPoseObservation.JointName.leftKnee), String(describing: VNHumanBodyPoseObservation.JointName.leftAnkle)),
        (String(describing: VNHumanBodyPoseObservation.JointName.rightHip), String(describing: VNHumanBodyPoseObservation.JointName.rightKnee)),
        (String(describing: VNHumanBodyPoseObservation.JointName.rightKnee), String(describing: VNHumanBodyPoseObservation.JointName.rightAnkle))
    ]

    private let visionQueue = DispatchQueue(label: "neon-gym.vision.pose")
    private let processingLock = NSLock()
    private let repCounter = SquatRepCounter()
    private var isProcessing = false

    func resetWorkout() {
        visionQueue.async { [weak self] in
            guard let self else { return }
            self.repCounter.reset()
            DispatchQueue.main.async {
                self.metrics = SquatMetrics(reps: 0, phase: .up, feedback: "Move into frame")
            }
        }
    }

    func processFrame(_ sampleBuffer: CMSampleBuffer) {
        processingLock.lock()
        guard !isProcessing else {
            processingLock.unlock()
            return
        }
        isProcessing = true
        processingLock.unlock()

        visionQueue.async { [weak self] in
            guard let self else { return }
            defer {
                self.processingLock.lock()
                self.isProcessing = false
                self.processingLock.unlock()
            }

            let request = VNDetectHumanBodyPoseRequest()
            let handler = VNImageRequestHandler(cmSampleBuffer: sampleBuffer,
                                                orientation: .up,
                                                options: [:])

            do {
                try handler.perform([request])
                guard let observation = request.results?.first else {
                    self.publish(points: [], metrics: self.repCounter.poseLost())
                    return
                }

                let recognizedPoints = try observation.recognizedPoints(.all)
                let points = recognizedPoints.compactMap { joint, point -> PosePoint? in
                    // At the bottom of a squat Vision can briefly lower the
                    // confidence of an ankle or knee, especially from a side
                    // camera angle. Keep usable landmarks for the rep state
                    // machine; it still requires a complete calibrated leg
                    // and consecutive frames before it can count a rep.
                    guard point.confidence > 0.15 else { return nil }
                    // Use the dictionary's joint key for both the overlay and
                    // the rep counter. VNRecognizedPoint.identifier can be a
                    // different imported string representation.
                    return PosePoint(id: visionJointKey(joint),
                                     location: point.location,
                                     confidence: point.confidence)
                }
                let coordinateMap = Dictionary(uniqueKeysWithValues: points.map { ($0.id, $0.location) })
                let metrics = self.repCounter.update(points: coordinateMap)
                self.publish(points: points, metrics: metrics)
            } catch {
                self.publishError(error)
            }
        }
    }

    private func publish(points: [PosePoint], metrics: SquatMetrics) {
        DispatchQueue.main.async { [weak self] in
            self?.points = points
            self?.isTracking = self?.hasSquatPose(points) ?? false
            self?.metrics = metrics
            self?.errorMessage = nil
        }
    }

    private func hasSquatPose(_ points: [PosePoint]) -> Bool {
        let ids = Set(points.map(\.id))
        let leftLeg = [
            visionJointKey(.leftHip),
            visionJointKey(.leftKnee),
            visionJointKey(.leftAnkle)
        ]
        let rightLeg = [
            visionJointKey(.rightHip),
            visionJointKey(.rightKnee),
            visionJointKey(.rightAnkle)
        ]
        let leftPartialLeg = [visionJointKey(.leftHip), visionJointKey(.leftKnee)]
        let rightPartialLeg = [visionJointKey(.rightHip), visionJointKey(.rightKnee)]
        return leftLeg.allSatisfy(ids.contains)
            || rightLeg.allSatisfy(ids.contains)
            || leftPartialLeg.allSatisfy(ids.contains)
            || rightPartialLeg.allSatisfy(ids.contains)
    }

    private func publishError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.isTracking = false
        }
    }
}
