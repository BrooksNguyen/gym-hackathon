import AVFoundation
import SwiftUI

struct WorkoutTrackingView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @StateObject private var tracker = VisionTrackingManager()
    @AppStorage("hasSeenTrackingTutorial") private var hasSeenTrackingTutorial = false
    @State private var showTutorial = true
    @State private var cameraPosition: AVCaptureDevice.Position = .front
    @State private var flashRep: Int? = nil
    @State private var showFlash: Bool = false
    @State private var flashIsGood: Bool = true
    @State private var sessionFinished: Bool = false
    @State private var isPaused: Bool = false
    @State private var breakSeconds: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        if sessionFinished {
            WorkoutSummaryView(reps: tracker.metrics.reps, exercise: "SQUAT") {
                dismiss()
            }
        } else {
            trackingView
        }
    }
    
    private var trackingView: some View {
        ZStack {
            Theme.trueBlack.ignoresSafeArea()

            if camera.permissionGranted {
                CameraPreviewView(session: camera.session,
                                  videoGravity: .resizeAspect,
                                  mirrored: cameraPosition == .front)
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
                
                feedbackPanel
                    .padding(.bottom, 24)
                
                bottomBar
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            
            if !hasSeenTrackingTutorial {
                TutorialOverlayView(
                    steps: [
                        "Step back so your full body is in frame.",
                        "Start your exercise. AI will track your reps and form in real-time."
                    ],
                    isPresented: $showTutorial
                )
                .onChange(of: showTutorial) { newValue in
                    if !newValue {
                        hasSeenTrackingTutorial = true
                    }
                }
            }
            
            // Flashing Rep Overlay
            if showFlash, let rep = flashRep {
                VStack(spacing: -30) {
                    Text("\(rep)")
                        .font(.system(size: 300, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: Theme.primaryAccent(for: .dark).opacity(0.8), radius: 30)
                    
                    Text(flashIsGood ? "GOOD" : "BAD")
                        .font(.system(size: 225, weight: .black, design: .rounded))
                        .foregroundColor(flashIsGood ? Theme.neonGreen : .red)
                        .shadow(color: (flashIsGood ? Theme.neonGreen : Color.red).opacity(0.8), radius: 30)
                        .minimumScaleFactor(0.3)
                        .lineLimit(1)
                }
                .transition(.scale(scale: 0.5).combined(with: .opacity))
                .zIndex(2)
            }
            
            // Paused Overlay
            if isPaused {
                ZStack {
                    Theme.trueBlack.opacity(0.85).ignoresSafeArea()
                    
                    VStack(spacing: 24) {
                        Text("PAUSED")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .tracking(4)
                            .foregroundColor(.white)
                        
                        Text(timeString(from: breakSeconds))
                            .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(Theme.primaryAccent(for: .dark))
                            .shadow(color: Theme.primaryAccent(for: .dark).opacity(0.5), radius: 20)
                        
                        Text("Rest up. Tap Resume when ready.")
                            .font(Theme.secondaryText)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .zIndex(3)
                .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .onChange(of: tracker.metrics.reps) { newReps in
            if newReps > 0 {
                flashRep = newReps
                
                let fb = tracker.metrics.feedback.lowercased()
                flashIsGood = fb.contains("good") || fb.contains("locked")
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    showFlash = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        showFlash = false
                    }
                }
            }
        }
        .onAppear {
            camera.onFrame = { sampleBuffer in
                if !isPaused {
                    tracker.processFrame(sampleBuffer)
                }
            }
            camera.start(position: cameraPosition)
        }
        .onDisappear {
            camera.onFrame = nil
            camera.stop()
            timer?.invalidate()
            timer = nil
        }
    }
    
    private func timeString(from totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
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
            
            Button {
                cameraPosition = cameraPosition == .front ? .back : .front
                tracker.recalibrateForCameraChange()
                camera.start(position: cameraPosition)
            } label: {
                Image(systemName: "camera.rotate.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }



    private var feedbackPanel: some View {
        let isPositiveFeedback = tracker.metrics.feedback.contains("Good")
            || tracker.metrics.feedback.contains("locked")

        return HStack(spacing: 8) {
            Image(systemName: isPositiveFeedback ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isPositiveFeedback ? .green : .orange)
            Text(tracker.metrics.feedback)
                .font(Theme.secondaryText)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.7), in: Capsule())
        .overlay(
            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
    }

    private var bottomBar: some View {
        HStack(spacing: 16) {
            Button {
                withAnimation {
                    isPaused.toggle()
                }
                if isPaused {
                    breakSeconds = 0
                    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        breakSeconds += 1
                    }
                } else {
                    timer?.invalidate()
                    timer = nil
                }
            } label: {
                Text(isPaused ? "Resume" : "Take a break")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(isPaused ? Theme.primaryAccent(for: .dark) : Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isPaused ? Color.clear : Color.white.opacity(0.3), lineWidth: 1)
                    )
            }
            
            Button {
                sessionFinished = true
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
