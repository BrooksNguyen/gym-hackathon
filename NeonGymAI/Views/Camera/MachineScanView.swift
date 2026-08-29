import SwiftUI
import UIKit

struct MachineScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @State private var capturedImage: UIImage?
    @State private var statusMessage = "Center the machine inside the frame"
    let onStartTracking: () -> Void

    var body: some View {
        ZStack {
            Theme.trueBlack.ignoresSafeArea()

            if camera.permissionGranted {
                CameraPreviewView(session: camera.session, mirrored: false)
                    .ignoresSafeArea()
                    .overlay {
                        if capturedImage == nil {
                            scannerOverlay
                        } else if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFill()
                                .ignoresSafeArea()
                        }
                    }
            } else {
                permissionView
            }

            VStack(spacing: 0) {
                header
                Spacer()

                if capturedImage == nil {
                    Text(statusMessage)
                        .font(Theme.digitalFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.65), in: Capsule())
                } else {
                    recommendationCard
                }

                captureButton
                    .padding(.top, 18)
                    .padding(.bottom, 22)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear { camera.start(position: .back) }
        .onDisappear { camera.stop() }
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(.black.opacity(0.65), in: Circle())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("MACHINE SCAN")
                    .font(.caption.weight(.bold))
                    .tracking(1.5)
                    .foregroundColor(Theme.neonCyan)
                Text(capturedImage == nil ? "AI AGENT READY" : "FRAME CAPTURED")
                    .font(.caption2.monospaced())
                    .foregroundColor(.white.opacity(0.75))
            }
        }
        .padding(.top, 12)
    }

    private var scannerOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Theme.neonCyan.opacity(0.9), style: StrokeStyle(lineWidth: 2, dash: [12, 8]))
                    .frame(width: proxy.size.width * 0.82, height: proxy.size.height * 0.45)

                Image(systemName: "viewfinder")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(Theme.neonCyan.opacity(0.8))
            }
        }
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 46))
                .foregroundColor(Theme.neonCyan)
            Text("Camera access is required")
                .font(Theme.titleFont)
                .foregroundColor(.white)
            Text(camera.errorMessage ?? "Allow camera access in Settings, then return to NeonGymAI.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .font(Theme.digitalFont)
        }
        .padding(30)
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("DEMO AI RECOMMENDATION", systemImage: "sparkles")
                .font(.caption.weight(.bold))
                .foregroundColor(Theme.neonCyan)
            Text("Squat station")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
            Text("Primary muscles: quads, glutes, hamstrings")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.75))
            Text("Suggested plan: 4 sets x 12 reps")
                .font(Theme.digitalFont)
                .foregroundColor(Theme.neonGreen)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.neonCyan.opacity(0.65), lineWidth: 1)
        }
    }

    private var captureButton: some View {
        Button {
            if capturedImage == nil {
                guard let data = camera.captureLatestFrameJPEGData(),
                      let image = UIImage(data: data) else {
                    statusMessage = "Waiting for a camera frame..."
                    return
                }
                capturedImage = image
            } else {
                onStartTracking()
                dismiss()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: capturedImage == nil ? "camera.fill" : "figure.run")
                Text(capturedImage == nil ? "Capture Machine" : "Start Squat Tracking")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.black)
            .background(capturedImage == nil ? Theme.neonCyan : Theme.neonGreen,
                        in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!camera.permissionGranted || !camera.isRunning)
        .opacity(camera.permissionGranted && camera.isRunning ? 1 : 0.45)
    }
}
