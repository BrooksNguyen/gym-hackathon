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

enum ExercisePhase: String {
    case up = "UP"
    case down = "DOWN"
}

enum ExerciseType: String {
    case squat = "SQUAT"
    case pushUp = "PUSH-UP"
}

struct CounterMetrics {
    let reps: Int
    let phase: ExercisePhase
    let feedback: String
}

struct WorkoutMetrics {
    let reps: Int
    let phase: ExercisePhase
    let feedback: String
    let exercise: ExerciseType?
    let candidate: ExerciseType?

    static let initial = WorkoutMetrics(reps: 0,
                                        phase: .up,
                                        feedback: "Move into frame",
                                        exercise: nil,
                                        candidate: nil)
}

private func visionJointKey(_ joint: VNHumanBodyPoseObservation.JointName) -> String {
    String(describing: joint)
}

/// Small, replaceable adapter for Dev1's exercise logic. It consumes the
/// normalized Vision landmarks and publishes metrics back to the tracking UI.
final class SquatRepCounter {
    private(set) var reps = 0
    private(set) var phase: ExercisePhase = .up
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

    /// Clears pose calibration without changing completed reps.
    func recalibrate() {
        resetMotion()
    }

    /// Cancels an in-progress rep after Vision loses the user's lower body.
    /// Returning to the frame must recalibrate before another rep can count.
    func poseLost() -> CounterMetrics {
        missingPoseFrames += 1
        if missingPoseFrames >= poseLossFrameCount {
            resetMotion()
            return metrics(feedback: "Pose lost - re-center and stand still")
        }
        return metrics(feedback: "Searching for your full lower body")
    }

    func update(points: [String: CGPoint]) -> CounterMetrics {
        guard hasUprightTorso(points) else {
            return poseLost()
        }

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

    func isPoseCandidate(_ points: [String: CGPoint]) -> Bool {
        hasUprightTorso(points) && squatSample(from: points) != nil
    }

    private func metrics(feedback: String) -> CounterMetrics {
        CounterMetrics(reps: reps, phase: phase, feedback: feedback)
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
    private func updateFromPartialPose(points: [String: CGPoint]) -> CounterMetrics {
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

    private func hasUprightTorso(_ points: [String: CGPoint]) -> Bool {
        let samples = [
            torsoSample(points: points, shoulder: .leftShoulder, hip: .leftHip),
            torsoSample(points: points, shoulder: .rightShoulder, hip: .rightHip)
        ].compactMap { $0 }

        guard let torso = samples.max(by: { $0.length < $1.length }) else {
            return false
        }

        // Squats can include a controlled forward lean, but the torso remains
        // substantially more vertical than it is during a push-up.
        return torso.verticalDistance > torso.horizontalDistance * 0.65
    }

    private func torsoSample(points: [String: CGPoint],
                             shoulder: VNHumanBodyPoseObservation.JointName,
                             hip: VNHumanBodyPoseObservation.JointName) -> (length: CGFloat, verticalDistance: CGFloat, horizontalDistance: CGFloat)? {
        guard let shoulderPoint = points[visionJointKey(shoulder)],
              let hipPoint = points[visionJointKey(hip)] else {
            return nil
        }

        let dx = abs(shoulderPoint.x - hipPoint.x)
        let dy = abs(shoulderPoint.y - hipPoint.y)
        let length = hypot(dx, dy)
        guard length > 0.05 else { return nil }
        return (length, dy, dx)
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

final class PushUpRepCounter {
    private(set) var reps = 0
    private(set) var phase: ExercisePhase = .up
    private var isArmed = false
    private var topFrames = 0
    private var downFrames = 0
    private var missingPoseFrames = 0
    private var activeViewMode: ViewMode?
    private var pendingViewMode: ViewMode?
    private var pendingViewFrames = 0
    // In an end-on view Vision can keep reporting a fairly open elbow angle
    // while the chest clearly lowers. Keep the calibrated shoulder-to-hand
    // height so that second motion signal can be used only for that view.
    private var calibratedEndOnArmHeight: CGFloat?
    private var endOnCalibrationHeightTotal: CGFloat = 0
    private var endOnCalibrationFrameCount = 0
    private var calibratedEndOnTopElbowAngle: CGFloat?
    private var endOnCalibrationElbowTotal: CGFloat = 0

    private let calibrationFrameCount = 4
    private let downFrameCount = 2
    private let completedTopFrameCount = 2
    private let poseLossFrameCount = 8
    private let viewChangeFrameCount = 4
    private let topElbowAngle: CGFloat = 130

    func reset() {
        reps = 0
        resetMotion()
    }

    /// Clears pose calibration without changing completed reps.
    func recalibrate() {
        resetMotion()
    }

    func poseLost() -> CounterMetrics {
        missingPoseFrames += 1
        if missingPoseFrames >= poseLossFrameCount {
            resetMotion()
            return metrics(feedback: "Push-up pose lost - show your full body")
        }
        return metrics(feedback: "Keep your shoulder, arm, hip and ankle visible")
    }

    func update(points: [String: CGPoint]) -> CounterMetrics {
        guard let sample = pushUpSample(from: points,
                                        allowRelaxedEndOn: activeViewMode == .upperBodyEndOn),
              isPushUpPose(sample) else {
            return poseLost()
        }

        // Never carry a half-completed rep from a side view into a front view
        // (or vice versa). A view has to remain changed for a few frames
        // before its calibration is reset, avoiding false changes from a
        // single missing landmark.
        if isChangingView(sample) {
            return metrics(feedback: "Camera angle changed - hold a high plank to recalibrate")
        }

        missingPoseFrames = 0
        // Do not require a perfectly straight arm at the top. This gives a
        // natural, slightly shorter lockout while preserving a clear gap from
        // the down-position threshold.
        let armHeight = sample.shoulderY - sample.wristY
        let torsoIsLoweredFromTop = sample.isUpperBodyOnly
            && calibratedEndOnArmHeight.map { armHeight < $0 * 0.94 } == true
        // Absolute elbow angles are less reliable from directly in front.
        // Compare against the user's own calibrated extension as well, so a
        // real bend is not mistaken for another top position.
        let endOnElbowIsBelowTop = sample.isUpperBodyOnly
            && calibratedEndOnTopElbowAngle.map { sample.elbowAngle < $0 - 8 } == true
        let isTopPosition = sample.elbowAngle > topElbowAngle
            && !torsoIsLoweredFromTop
            && !endOnElbowIsBelowTop
        if isTopPosition {
            topFrames += 1
            downFrames = 0

            if !isArmed && sample.isUpperBodyOnly {
                endOnCalibrationHeightTotal += armHeight
                endOnCalibrationFrameCount += 1
                endOnCalibrationElbowTotal += sample.elbowAngle
            }

            if topFrames >= calibrationFrameCount && !isArmed {
                isArmed = true
                if sample.isUpperBodyOnly, endOnCalibrationFrameCount > 0 {
                    // Freeze the initial high-plank height. Updating it after
                    // every rep lets a single noisy frame make all later
                    // lowers appear too small to count.
                    calibratedEndOnArmHeight = endOnCalibrationHeightTotal
                        / CGFloat(endOnCalibrationFrameCount)
                    calibratedEndOnTopElbowAngle = endOnCalibrationElbowTotal
                        / CGFloat(endOnCalibrationFrameCount)
                }
            }

            if phase == .down && topFrames >= completedTopFrameCount {
                phase = .up
                if isArmed {
                    reps += 1
                }
            }

            let feedback: String
            if phase == .down {
                feedback = "Finish pressing up to complete the rep"
            } else if !isArmed {
                feedback = "Hold a high plank to calibrate"
            } else if sample.bodyLineAngle < 150 {
                feedback = "Keep your hips in line with your shoulders"
            } else {
                feedback = "Good push-up form - lower with control"
            }
            return metrics(feedback: feedback)
        }

        topFrames = 0
        if !isArmed {
            endOnCalibrationHeightTotal = 0
            endOnCalibrationFrameCount = 0
            endOnCalibrationElbowTotal = 0
        }
        guard isArmed else {
            return metrics(feedback: "Start in a straight-arm high plank")
        }

        // The top can now finish at a shorter 130-degree extension. Keep a
        // separate, deeper down threshold so the states never overlap and a
        // small arm wobble cannot produce a rep.
        let downAngleThreshold: CGFloat
        if sample.isUpperBodyOnly {
            // Keep a floor for safety, but adapt to the person's actual
            // straight-arm angle instead of requiring an arbitrary 120/128°.
            downAngleThreshold = max(128, (calibratedEndOnTopElbowAngle ?? 143) - 15)
        } else {
            downAngleThreshold = isForeshortenedEndOnView(sample) ? 128 : 110
        }
        let elbowsBent = sample.elbowAngle < downAngleThreshold
        // Face-on and back-on views foreshorten the elbow. A clear shoulder
        // drop toward fixed hands is therefore also a valid down signal, but
        // only after a high-plank height has been calibrated.
        let loweredChestInEndOnView = sample.isUpperBodyOnly && torsoIsLoweredFromTop
        let bodyIsStable = sample.bodyLineAngle > 125
        if (elbowsBent || loweredChestInEndOnView) && bodyIsStable {
            downFrames += 1
            // At the front/back angle Vision may recognize the bottom for
            // only one processed frame. Once that frame has a clear bend or
            // chest drop, latch DOWN until two reliable top frames confirm
            // the return and complete the rep.
            let requiredDownFrames = sample.isUpperBodyOnly ? 1 : downFrameCount
            if downFrames >= requiredDownFrames {
                phase = .down
            }
            return metrics(feedback: phase == .down
                           ? "Press through your hands to return up"
                           : "Lower a little further")
        }

        downFrames = 0
        return metrics(feedback: sample.bodyLineAngle <= 135
                       ? "Keep your body in one straight line"
                       : sample.isUpperBodyOnly
                           ? "Lower your chest toward your hands"
                           : "Bend your elbows to lower your chest")
    }

    func isPoseCandidate(_ points: [String: CGPoint]) -> Bool {
        guard let sample = pushUpSample(from: points) else { return false }
        return isPushUpPose(sample) && sample.bodyLineAngle > 120
    }

    private func resetMotion() {
        resetRepState()
        activeViewMode = nil
        pendingViewMode = nil
        pendingViewFrames = 0
    }

    private func resetRepState() {
        phase = .up
        isArmed = false
        topFrames = 0
        downFrames = 0
        missingPoseFrames = 0
        calibratedEndOnArmHeight = nil
        endOnCalibrationHeightTotal = 0
        endOnCalibrationFrameCount = 0
        calibratedEndOnTopElbowAngle = nil
        endOnCalibrationElbowTotal = 0
    }

    private func metrics(feedback: String) -> CounterMetrics {
        CounterMetrics(reps: reps, phase: phase, feedback: feedback)
    }

    private struct Sample {
        let elbowAngle: CGFloat
        let bodyLineAngle: CGFloat
        let armSpan: CGFloat
        let wristY: CGFloat
        let shoulderY: CGFloat
        let hipY: CGFloat
        let ankleY: CGFloat
        let isHorizontal: Bool
        let isUpperBodyOnly: Bool
        let viewMode: ViewMode
    }

    private enum ViewMode: Equatable {
        case side
        case endOn
        case upperBodyEndOn
    }

    private func isChangingView(_ sample: Sample) -> Bool {
        guard let activeViewMode else {
            self.activeViewMode = sample.viewMode
            return false
        }

        guard activeViewMode != sample.viewMode else {
            pendingViewMode = nil
            pendingViewFrames = 0
            return false
        }

        if pendingViewMode == sample.viewMode {
            pendingViewFrames += 1
        } else {
            pendingViewMode = sample.viewMode
            pendingViewFrames = 1
        }

        if pendingViewFrames >= viewChangeFrameCount {
            self.activeViewMode = sample.viewMode
            pendingViewMode = nil
            pendingViewFrames = 0
            resetRepState()
        }

        return true
    }

    private func isPushUpPose(_ sample: Sample) -> Bool {
        if sample.isUpperBodyOnly {
            return true
        }

        if sample.isHorizontal {
            return true
        }

        // At either end of the body (face-on or back-on), the body axis is
        // foreshortened and no longer looks horizontal in 2D. Hands, hips and
        // ankles still cluster near the floor, unlike a standing pose.
        return isForeshortenedEndOnView(sample)
    }

    /// An end-on view can be either face-on or back-on. Neither requires face
    /// landmarks; the body axis is simply foreshortened in the 2D image.
    private func isForeshortenedEndOnView(_ sample: Sample) -> Bool {
        guard !sample.isHorizontal else { return false }
        let handsNearAnkles = abs(sample.wristY - sample.ankleY) < 0.30
        let hipsNearAnkles = abs(sample.hipY - sample.ankleY) < 0.30
        return handsNearAnkles && hipsNearAnkles && sample.bodyLineAngle > 120
    }

    private func pushUpSample(from points: [String: CGPoint],
                              allowRelaxedEndOn: Bool = false) -> Sample? {
        let samples = [
            sideSample(points: points,
                       shoulder: .leftShoulder,
                       elbow: .leftElbow,
                       wrist: .leftWrist,
                       hip: .leftHip,
                       ankle: .leftAnkle),
            sideSample(points: points,
                       shoulder: .rightShoulder,
                       elbow: .rightElbow,
                       wrist: .rightWrist,
                       hip: .rightHip,
                       ankle: .rightAnkle)
        ].compactMap { $0 }

        // Once a front/back push-up view is established, keep using both arm
        // landmarks for the workout. A slightly noisy elbow or wrist at the
        // bottom must not switch the state machine to a one-arm side sample.
        if allowRelaxedEndOn,
           let endOnSample = endOnArmSample(from: points, relaxed: true) {
            return endOnSample
        }

        // A profile or diagonal view often hides one side. Prefer that
        // full-body path only when the body itself is visibly horizontal.
        // In a face-on/back-on view, a noisy hip or ankle can otherwise make
        // this one-arm sample look valid and bypass the much more reliable
        // symmetric two-arm model below.
        if let sideSample = samples
            .filter({ $0.isHorizontal })
            .max(by: { $0.armSpan < $1.armSpan }) {
            return sideSample
        }

        // Prefer both arms for either end of the body, whether or not lower
        // body landmarks happen to be visible in that frame.
        if let endOnSample = endOnArmSample(from: points) {
            return endOnSample
        }

        // One arm is still better than no tracking for an oblique end-on
        // camera angle where the far arm is occluded.
        return samples.max(by: { $0.armSpan < $1.armSpan })
    }

    private func sideSample(points: [String: CGPoint],
                            shoulder: VNHumanBodyPoseObservation.JointName,
                            elbow: VNHumanBodyPoseObservation.JointName,
                            wrist: VNHumanBodyPoseObservation.JointName,
                            hip: VNHumanBodyPoseObservation.JointName,
                            ankle: VNHumanBodyPoseObservation.JointName) -> Sample? {
        guard let shoulderPoint = points[visionJointKey(shoulder)],
              let elbowPoint = points[visionJointKey(elbow)],
              let wristPoint = points[visionJointKey(wrist)],
              let hipPoint = points[visionJointKey(hip)],
              let anklePoint = points[visionJointKey(ankle)] else {
            return nil
        }

        let bodyDX = anklePoint.x - shoulderPoint.x
        let bodyDY = anklePoint.y - shoulderPoint.y
        let bodyLength = hypot(bodyDX, bodyDY)
        guard bodyLength > 0.2 else { return nil }

        let rawBodyAngle = abs(atan2(bodyDY, bodyDX) * 180 / .pi)
        let angleFromHorizontal = min(rawBodyAngle, 180 - rawBodyAngle)
        let upperArm = hypot(shoulderPoint.x - elbowPoint.x,
                             shoulderPoint.y - elbowPoint.y)
        let forearm = hypot(wristPoint.x - elbowPoint.x,
                            wristPoint.y - elbowPoint.y)

        return Sample(elbowAngle: angle(from: shoulderPoint,
                                        through: elbowPoint,
                                        to: wristPoint),
                      bodyLineAngle: angle(from: shoulderPoint,
                                           through: hipPoint,
                                           to: anklePoint),
                      armSpan: upperArm + forearm,
                      wristY: wristPoint.y,
                      shoulderY: shoulderPoint.y,
                      hipY: hipPoint.y,
                      ankleY: anklePoint.y,
                      isHorizontal: angleFromHorizontal < 40,
                      isUpperBodyOnly: false,
                      viewMode: angleFromHorizontal < 40 ? .side : .endOn)
    }

    /// End-on push-ups (face-on or back-on) can hide hips and ankles behind
    /// the torso. This fallback needs both arms and synchronized elbow motion,
    /// so it does not depend on face points. Do not require hands to be wider
    /// than the shoulders: from a true face-on view, Vision frequently places
    /// the wrists almost directly below the shoulders.
    private func endOnArmSample(from points: [String: CGPoint],
                                relaxed: Bool = false) -> Sample? {
        guard let leftShoulder = points[visionJointKey(.leftShoulder)],
              let leftElbow = points[visionJointKey(.leftElbow)],
              let leftWrist = points[visionJointKey(.leftWrist)],
              let rightShoulder = points[visionJointKey(.rightShoulder)],
              let rightElbow = points[visionJointKey(.rightElbow)],
              let rightWrist = points[visionJointKey(.rightWrist)] else {
            return nil
        }

        let shoulderSpan = abs(rightShoulder.x - leftShoulder.x)
        let handSpan = abs(rightWrist.x - leftWrist.x)
        let leftAngle = angle(from: leftShoulder, through: leftElbow, to: leftWrist)
        let rightAngle = angle(from: rightShoulder, through: rightElbow, to: rightWrist)
        let averageWristY = (leftWrist.y + rightWrist.y) / 2
        let averageShoulderY = (leftShoulder.y + rightShoulder.y) / 2

        let shouldersAreVisible = shoulderSpan > 0.04
        let handsAreSeparated = handSpan > 0.03
        // Hands may be slightly inside the shoulder line in a narrow or
        // face-on push-up, but should still form a two-sided base rather than
        // collapse onto one tracked point.
        let handsMatchBodyWidth = handSpan > shoulderSpan * 0.35
        // Relative height works at any camera distance. In an end-on plank,
        // hands sit materially below shoulders from either direction.
        let wristsAreLow = averageShoulderY - averageWristY > 0.06
        // The elbow can move beside, rather than precisely between, shoulder
        // and wrist in a front camera view. The complete arm still has to
        // reach meaningfully downward on both sides.
        let bothArmsReachHands = leftShoulder.y - leftWrist.y > 0.08
            && rightShoulder.y - rightWrist.y > 0.08
        // The elbows can be detected at different depths from a direct
        // camera angle, particularly at the bottom. Keep a broad agreement
        // check so a brief one-arm wobble does not switch detection modes.
        let elbowsMoveTogether = abs(leftAngle - rightAngle) < 90

        if !relaxed {
            guard shouldersAreVisible,
                  handsAreSeparated,
                  handsMatchBodyWidth,
                  wristsAreLow,
                  bothArmsReachHands,
                  elbowsMoveTogether else {
                return nil
            }
        }

        let leftArmSpan = hypot(leftShoulder.x - leftElbow.x, leftShoulder.y - leftElbow.y)
            + hypot(leftWrist.x - leftElbow.x, leftWrist.y - leftElbow.y)
        let rightArmSpan = hypot(rightShoulder.x - rightElbow.x, rightShoulder.y - rightElbow.y)
            + hypot(rightWrist.x - rightElbow.x, rightWrist.y - rightElbow.y)

        return Sample(elbowAngle: (leftAngle + rightAngle) / 2,
                      bodyLineAngle: 180,
                      armSpan: (leftArmSpan + rightArmSpan) / 2,
                      wristY: averageWristY,
                      shoulderY: averageShoulderY,
                      hipY: averageWristY,
                      ankleY: averageWristY,
                      isHorizontal: false,
                      isUpperBodyOnly: true,
                      viewMode: .upperBodyEndOn)
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

/// Runs both motion detectors until the first complete rep identifies the
/// exercise. After that, only the locked detector receives frames, preventing
/// another exercise or unrelated movement from increasing the rep count.
final class WorkoutRepCounter {
    private let squatCounter = SquatRepCounter()
    private let pushUpCounter = PushUpRepCounter()
    private(set) var lockedExercise: ExerciseType?

    func reset() {
        lockedExercise = nil
        squatCounter.reset()
        pushUpCounter.reset()
    }

    /// A new camera direction changes every landmark's geometry. Keep the
    /// workout total and locked exercise, but never carry an in-progress rep
    /// or old calibration into that new view.
    func recalibrateForCameraChange() -> WorkoutMetrics {
        switch lockedExercise {
        case .squat:
            squatCounter.recalibrate()
            return WorkoutMetrics(reps: squatCounter.reps,
                                  phase: .up,
                                  feedback: "Camera changed - stand tall to recalibrate",
                                  exercise: .squat,
                                  candidate: nil)
        case .pushUp:
            pushUpCounter.recalibrate()
            return WorkoutMetrics(reps: pushUpCounter.reps,
                                  phase: .up,
                                  feedback: "Camera changed - hold a high plank to recalibrate",
                                  exercise: .pushUp,
                                  candidate: nil)
        case nil:
            squatCounter.recalibrate()
            pushUpCounter.recalibrate()
            return WorkoutMetrics(reps: 0,
                                  phase: .up,
                                  feedback: "Camera changed - find your exercise again",
                                  exercise: nil,
                                  candidate: nil)
        }
    }

    func poseLost() -> WorkoutMetrics {
        switch lockedExercise {
        case .squat:
            return workoutMetrics(from: squatCounter.poseLost(), exercise: .squat)
        case .pushUp:
            return workoutMetrics(from: pushUpCounter.poseLost(), exercise: .pushUp)
        case nil:
            _ = squatCounter.poseLost()
            _ = pushUpCounter.poseLost()
            return WorkoutMetrics(reps: 0,
                                  phase: .up,
                                  feedback: "Move your full body into frame",
                                  exercise: nil,
                                  candidate: nil)
        }
    }

    func update(points: [String: CGPoint]) -> WorkoutMetrics {
        switch lockedExercise {
        case .squat:
            return workoutMetrics(from: squatCounter.update(points: points), exercise: .squat)
        case .pushUp:
            return workoutMetrics(from: pushUpCounter.update(points: points), exercise: .pushUp)
        case nil:
            break
        }

        let pushUpCandidate = pushUpCounter.isPoseCandidate(points)
        let squatCandidate = squatCounter.isPoseCandidate(points)
        let squatMetrics = squatCounter.update(points: points)
        let pushUpMetrics = pushUpCounter.update(points: points)

        if pushUpMetrics.reps > 0 {
            lockedExercise = .pushUp
            squatCounter.reset()
            return WorkoutMetrics(reps: pushUpMetrics.reps,
                                  phase: pushUpMetrics.phase,
                                  feedback: "PUSH-UP locked - keep going",
                                  exercise: .pushUp,
                                  candidate: nil)
        }

        if squatMetrics.reps > 0 {
            lockedExercise = .squat
            pushUpCounter.reset()
            return WorkoutMetrics(reps: squatMetrics.reps,
                                  phase: squatMetrics.phase,
                                  feedback: "SQUAT locked - keep going",
                                  exercise: .squat,
                                  candidate: nil)
        }

        if pushUpCandidate {
            return WorkoutMetrics(reps: 0,
                                  phase: pushUpMetrics.phase,
                                  feedback: pushUpMetrics.feedback,
                                  exercise: nil,
                                  candidate: .pushUp)
        }

        if squatCandidate {
            return WorkoutMetrics(reps: 0,
                                  phase: squatMetrics.phase,
                                  feedback: squatMetrics.feedback,
                                  exercise: nil,
                                  candidate: .squat)
        }

        return WorkoutMetrics(reps: 0,
                              phase: .up,
                              feedback: "Stand for a squat or hold a high plank",
                              exercise: nil,
                              candidate: nil)
    }

    private func workoutMetrics(from metrics: CounterMetrics,
                                exercise: ExerciseType) -> WorkoutMetrics {
        WorkoutMetrics(reps: metrics.reps,
                       phase: metrics.phase,
                       feedback: metrics.feedback,
                       exercise: exercise,
                       candidate: nil)
    }
}

final class VisionTrackingManager: ObservableObject {
    @Published private(set) var points: [PosePoint] = []
    @Published private(set) var isTracking = false
    @Published private(set) var metrics = WorkoutMetrics.initial
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
    private let repCounter = WorkoutRepCounter()
    private var isProcessing = false
    private var lastDisplayPoints: [String: PosePoint] = [:]
    private var staleDisplayFrames = 0
    private let maxStaleDisplayFrames = 4
    private let minimumStablePointCount = 6

    func resetWorkout() {
        visionQueue.async { [weak self] in
            guard let self else { return }
            self.repCounter.reset()
            self.lastDisplayPoints.removeAll()
            self.staleDisplayFrames = 0
            DispatchQueue.main.async {
                self.metrics = .initial
            }
        }
    }

    /// Use when switching front/back cameras so one perspective cannot finish
    /// a rep that began in another perspective.
    func recalibrateForCameraChange() {
        visionQueue.async { [weak self] in
            guard let self else { return }
            let metrics = self.repCounter.recalibrateForCameraChange()
            self.lastDisplayPoints.removeAll()
            self.staleDisplayFrames = 0
            DispatchQueue.main.async {
                self.points = []
                self.isTracking = false
                self.metrics = metrics
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

    private func publish(points: [PosePoint], metrics: WorkoutMetrics) {
        let displayPoints = smoothedDisplayPoints(from: points)
        DispatchQueue.main.async { [weak self] in
            self?.points = displayPoints
            self?.isTracking = self?.hasTrackablePose(displayPoints) ?? false
            self?.metrics = metrics
            self?.errorMessage = nil
        }
    }

    /// Vision can miss one frame when a joint is occluded or motion blur is
    /// present. Keep the last known joints on screen for a few processed
    /// frames, and merge missing joints with the latest reliable observation.
    /// The rep counter still receives the raw points, so this only stabilizes
    /// the visual overlay and cannot create a rep.
    private func smoothedDisplayPoints(from points: [PosePoint]) -> [PosePoint] {
        if points.count < minimumStablePointCount {
            staleDisplayFrames += 1
        } else {
            staleDisplayFrames = 0
        }

        if staleDisplayFrames > maxStaleDisplayFrames {
            lastDisplayPoints.removeAll()
            return points
        }

        for point in points {
            if let previous = lastDisplayPoints[point.id] {
                let smoothing: CGFloat = 0.7
                let location = CGPoint(
                    x: previous.location.x * (1 - smoothing) + point.location.x * smoothing,
                    y: previous.location.y * (1 - smoothing) + point.location.y * smoothing
                )
                lastDisplayPoints[point.id] = PosePoint(id: point.id,
                                                        location: location,
                                                        confidence: point.confidence)
            } else {
                lastDisplayPoints[point.id] = point
            }
        }

        return Array(lastDisplayPoints.values)
    }

    private func hasTrackablePose(_ points: [PosePoint]) -> Bool {
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
        let leftPushUpSide = [
            visionJointKey(.leftShoulder),
            visionJointKey(.leftElbow),
            visionJointKey(.leftWrist),
            visionJointKey(.leftHip),
            visionJointKey(.leftAnkle)
        ]
        let rightPushUpSide = [
            visionJointKey(.rightShoulder),
            visionJointKey(.rightElbow),
            visionJointKey(.rightWrist),
            visionJointKey(.rightHip),
            visionJointKey(.rightAnkle)
        ]
        return leftLeg.allSatisfy(ids.contains)
            || rightLeg.allSatisfy(ids.contains)
            || leftPartialLeg.allSatisfy(ids.contains)
            || rightPartialLeg.allSatisfy(ids.contains)
            || leftPushUpSide.allSatisfy(ids.contains)
            || rightPushUpSide.allSatisfy(ids.contains)
    }

    private func publishError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.isTracking = false
        }
    }
}
