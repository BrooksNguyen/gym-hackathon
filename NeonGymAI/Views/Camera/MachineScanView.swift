import SwiftUI
import UIKit

struct MachineScanView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var camera = CameraManager()
    @State private var capturedImage: UIImage?
    @State private var analysisResult: MachineAnalysisResponse?
    @State private var isAnalyzing = false
    @State private var scanError: String?
    @State private var storyboardImage: UIImage?
    @State private var isGeneratingStoryboard = false
    @State private var storyboardUnavailable = false
    @State private var storyboardFailureMessage: String?
    @State private var scanRequestID = UUID()
    @State private var storyboardRequestID = UUID()
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
                } else if isAnalyzing {
                    analyzingCard
                } else if let analysisResult {
                    recommendationCard(for: analysisResult)
                } else if let scanError {
                    errorCard(message: scanError)
                } else {
                    Text("Ready to scan this machine")
                        .font(Theme.digitalFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.black.opacity(0.65), in: Capsule())
                }

                captureButton
                    .padding(.top, 18)
                    .padding(.bottom, 22)
            }
            .padding(.horizontal, 20)
        }
        .preferredColorScheme(.dark)
        .onAppear { camera.start(position: .back) }
        .onDisappear {
            scanRequestID = UUID()
            storyboardRequestID = UUID()
            camera.stop()
        }
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
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Image(systemName: "viewfinder")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(Theme.neonCyan.opacity(0.8))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
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
                captureAndAnalyze()
            } else {
                resetScan()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: capturedImage == nil ? "camera.fill" : "arrow.clockwise")
                Text(capturedImage == nil ? "Scan Machine" : "Scan Another")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.black)
            .background(Theme.neonCyan, in: RoundedRectangle(cornerRadius: 16))
        }
        .disabled(!camera.permissionGranted || !camera.isRunning || isAnalyzing)
        .opacity(camera.permissionGranted && camera.isRunning && !isAnalyzing ? 1 : 0.45)
    }

    private var analyzingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Theme.neonCyan)
            VStack(alignment: .leading, spacing: 4) {
                Text("ANALYZING MACHINE")
                    .font(.caption.weight(.bold))
                    .tracking(1.1)
                    .foregroundColor(Theme.neonCyan)
                Text("Gemini is identifying the equipment and its main muscles.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
    }

    private func recommendationCard(for result: MachineAnalysisResponse) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                Text(result.machineName)
                    .font(.title.weight(.bold))
                    .foregroundColor(.white)

                HStack(alignment: .center, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TARGET MUSCLES")
                            .font(.caption.weight(.bold))
                            .tracking(1.1)
                            .foregroundColor(.white.opacity(0.6))
                        Text(result.targetMuscles.joined(separator: " • "))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(Theme.neonGreen)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)

                    VStack(spacing: 2) {
                        Text("TARGET")
                            .font(.caption2.weight(.bold))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.62))
                        Text("\(result.recommendedReps)")
                            .font(.system(size: 52, weight: .black, design: .rounded))
                            .foregroundColor(Theme.neonCyan)
                        Text("REPS")
                            .font(.caption2.weight(.bold))
                            .tracking(1)
                            .foregroundColor(.white.opacity(0.76))
                    }
                    .frame(minWidth: 92)
                    .padding(.vertical, 8)
                    .background(Theme.neonCyan.opacity(0.12), in: RoundedRectangle(cornerRadius: 14))
                }

                Divider().overlay(.white.opacity(0.2))

                storyboardSection(for: result)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 500)
        .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Theme.neonCyan.opacity(0.65), lineWidth: 1)
        }
    }

    private func storyboardSection(for result: MachineAnalysisResponse) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("HOW IT MOVES", systemImage: "figure.strengthtraining.traditional")
                .font(.caption.weight(.bold))
                .tracking(1.1)
                .foregroundColor(.white.opacity(0.6))

            if let storyboardImage {
                ZStack(alignment: .bottom) {
                    Image(uiImage: storyboardImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipped()
                        .accessibilityLabel("\(result.machineName) visual guide")
                        .accessibilityHint("The left panel shows the start position and the right panel shows the finish position. Target muscles are highlighted in red.")

                    HStack(spacing: 0) {
                        ForEach(["START", "FINISH"], id: \.self) { label in
                            Text(label)
                                .font(.caption2.monospaced().weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.68))
                        }
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Theme.neonCyan.opacity(0.45), lineWidth: 1)
                }
            } else if isGeneratingStoryboard {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(Theme.neonCyan)
                    Text("Generating your visual guide…")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.78))
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            } else if storyboardUnavailable {
                VStack(spacing: 10) {
                    if let storyboardFailureMessage {
                        Text(storyboardFailureMessage)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .lineLimit(4)
                    }

                    Button {
                        requestStoryboard(for: result, forceRefresh: true)
                    } label: {
                        Label("Retry visual guide", systemImage: "arrow.clockwise")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
            }
        }
    }

    private func errorCard(message: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("SCAN FAILED", systemImage: "exclamationmark.triangle.fill")
                .font(.caption.weight(.bold))
                .foregroundColor(.orange)
            Text(message)
                .font(.footnote)
                .foregroundColor(.white.opacity(0.86))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
    }

    private func captureAndAnalyze() {
        guard let data = camera.captureLatestFrameJPEGData(),
              let image = UIImage(data: data) else {
            statusMessage = "Waiting for a camera frame..."
            return
        }

        capturedImage = image
        analysisResult = nil
        scanError = nil
        storyboardImage = nil
        isGeneratingStoryboard = false
        storyboardUnavailable = false
        storyboardFailureMessage = nil
        let requestID = UUID()
        scanRequestID = requestID
        storyboardRequestID = UUID()
        isAnalyzing = true

        LLMNetworkManager.shared.scanMachine(
            imageData: data,
            currentEnergy: 100,
            fatiguedMuscles: []
        ) { result in
            guard scanRequestID == requestID else { return }

            withAnimation(.easeInOut(duration: 0.25)) {
                isAnalyzing = false
                switch result {
                case .success(let response):
                    analysisResult = response
                    requestStoryboard(for: response)
                case .failure(let error):
                    scanError = message(for: error)
                }
            }
        }
    }

    private func resetScan() {
        capturedImage = nil
        analysisResult = nil
        scanError = nil
        storyboardImage = nil
        isGeneratingStoryboard = false
        storyboardUnavailable = false
        storyboardFailureMessage = nil
        scanRequestID = UUID()
        storyboardRequestID = UUID()
        isAnalyzing = false
        statusMessage = "Center the machine inside the frame"
    }

    private func requestStoryboard(for result: MachineAnalysisResponse, forceRefresh: Bool = false) {
        let requestID = UUID()
        storyboardRequestID = requestID
        storyboardImage = nil
        storyboardUnavailable = false
        storyboardFailureMessage = nil
        isGeneratingStoryboard = true

        LLMNetworkManager.shared.generateMachineInstructionStoryboard(
            machineName: result.machineName,
            instructions: result.instructions,
            targetMuscles: result.targetMuscles,
            forceRefresh: forceRefresh
        ) { response in
            guard storyboardRequestID == requestID else { return }

            withAnimation(.easeInOut(duration: 0.25)) {
                isGeneratingStoryboard = false
                switch response {
                case .success(let imageData):
                    if let image = UIImage(data: imageData) {
                        storyboardImage = image
                    } else if !forceRefresh {
                        requestStoryboard(for: result, forceRefresh: true)
                    } else {
                        storyboardUnavailable = true
                        storyboardFailureMessage = "The visual guide returned an image this phone could not display."
                    }
                case .failure(let error):
                    storyboardUnavailable = true
                    storyboardFailureMessage = error.localizedDescription
                }
            }
        }
    }

    private func message(for error: Error) -> String {
        if case LLMNetworkManager.LLMError.missingAPIKey = error {
            return "Gemini API key is not configured. Add GEMINI_API_KEY to the app's run environment before scanning."
        }
        if case LLMNetworkManager.LLMError.noData = error {
            return "No camera frame was available. Point at the machine and try again."
        }
        return error.localizedDescription
    }
}
