import AVFoundation
import SwiftUI

struct WorkoutTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @StateObject private var tracker = VisionTrackingManager()
    @State private var cameraPosition: AVCaptureDevice.Position = .front

    var body: some View {
        ZStack {
            Theme.trueBlack.ignoresSafeArea()

            if camera.permissionGranted {
                CameraPreviewView(session: camera.session,
                                  videoGravity: .resizeAspect,
                                  mirrored: cameraPosition == .front)
                    .ignoresSafeArea()
                SkeletonOverlay(points: tracker.points,
                                mirrored: cameraPosition == .front,
                                videoGravity: .resizeAspect)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 14) {
                    Image(systemName: "figure.run")
                        .font(.system(size: 48))
                        .foregroundColor(Theme.neonGreen)
                    Text(camera.errorMessage ?? "Camera access is required for tracking")
                        .font(Theme.digitalFont)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                metricsPanel
                feedbackPanel
            }
            .padding(.horizontal, 18)
            .padding(.top, 12)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            camera.onFrame = { sampleBuffer in
                tracker.processFrame(sampleBuffer)
            }
            camera.start(position: cameraPosition)
        }
        .onDisappear {
            camera.onFrame = nil
            camera.stop()
        }
    }

    private var topBar: some View {
        HStack(alignment: .top) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.7), in: Circle())
            }

            Spacer()

            HStack(spacing: 10) {
                Button {
                    cameraPosition = cameraPosition == .front ? .back : .front
                    tracker.recalibrateForCameraChange()
                    camera.start(position: cameraPosition)
                } label: {
                    Image(systemName: "camera.rotate.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.black.opacity(0.7), in: Circle())
                }

                Button {
                    tracker.resetWorkout()
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.headline)
                        .foregroundColor(Theme.neonGreen)
                        .padding(12)
                        .background(.black.opacity(0.7), in: Circle())
                }

                VStack(alignment: .trailing, spacing: 5) {
                    Text(trackingTitle)
                        .font(.caption.weight(.bold))
                        .tracking(1.5)
                        .foregroundColor(Theme.neonGreen)
                    HStack(spacing: 6) {
                        Circle()
                            .fill(tracker.isTracking ? Theme.neonGreen : .orange)
                            .frame(width: 8, height: 8)
                        Text(tracker.isTracking ? "POSE LOCKED" : "SEARCHING")
                            .font(.caption2.monospaced())
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
    }

    private var trackingTitle: String {
        if let exercise = tracker.metrics.exercise {
            return "\(exercise.rawValue) LOCKED"
        }
        if let candidate = tracker.metrics.candidate {
            return "DETECTING \(candidate.rawValue)"
        }
        return "AUTO TRACKING"
    }

    private var metricsPanel: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                metric(value: "\(tracker.metrics.reps)",
                       label: "REPS",
                       color: Theme.neonGreen,
                       valueFontSize: 72)
                    .frame(width: geometry.size.width * 0.5)

                metric(value: tracker.metrics.phase.rawValue,
                       label: "PHASE",
                       color: Theme.neonCyan)
                metric(value: "4 x 12", label: "TARGET", color: .white)
            }
        }
        .frame(height: 132)
    }

    private func metric(value: String,
                        label: String,
                        color: Color,
                        valueFontSize: CGFloat = 24) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: valueFontSize, weight: .bold, design: .monospaced))
                .foregroundColor(color)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.black.opacity(0.75), in: RoundedRectangle(cornerRadius: 14))
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.35), lineWidth: 1)
        }
    }

    private var feedbackPanel: some View {
        let isPositiveFeedback = tracker.metrics.feedback.contains("Good")
            || tracker.metrics.feedback.contains("locked")

        return HStack(spacing: 10) {
            Image(systemName: isPositiveFeedback ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isPositiveFeedback ? Theme.neonGreen : .orange)
            Text(tracker.metrics.feedback)
                .font(Theme.digitalFont)
                .foregroundColor(.white)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 14))
        .padding(.vertical, 14)
    }
}
