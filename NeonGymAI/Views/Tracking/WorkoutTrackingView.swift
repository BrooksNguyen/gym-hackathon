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
                        .font(.system(size: 120))
                        .foregroundColor(.white.opacity(0.05))
                }
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                metricsPanel
                feedbackPanel
                bottomBar
                    .padding(.top, 16)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
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
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2), in: Circle())
            }
            
            Spacer()
            
            Text("CHECK FORM: \(tracker.metrics.exercise?.rawValue.uppercased() ?? "SQUAT")")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .cornerRadius(8)
            
            Spacer()
            
            Button {
                // sound toggle logic placeholder
            } label: {
                Image(systemName: "speaker.wave.2.fill")
                    .font(.system(size: 18))
                    .foregroundColor(Theme.primaryAccent(for: colorScheme))
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
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

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button {
                // Pause logic placeholder
            } label: {
                Text("Take a break")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Button {
                dismiss()
            } label: {
                Text("Finish")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color(red: 0.95, green: 0.25, blue: 0.3)) // Matches the red in screenshot
                    .cornerRadius(10)
            }
        }
    }
}
