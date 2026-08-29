import SwiftUI
import UIKit

private let themeAccent = Theme.primaryAccent(for: .dark)

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
                        .font(Theme.secondaryText)
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
                    Text("Ready to scan")
                        .font(Theme.secondaryText)
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
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.white.opacity(0.2), in: Circle())
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("MACHINE SCAN")
                    .font(Theme.tertiaryText)
                    .foregroundColor(themeAccent)
                Text(capturedImage == nil ? "AI READY" : "CAPTURED")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.top, 12)
    }

    private var scannerOverlay: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .stroke(themeAccent.opacity(0.7), style: StrokeStyle(lineWidth: 2, dash: [12, 8]))
                    .frame(width: proxy.size.width * 0.82, height: proxy.size.height * 0.45)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)

                Image(systemName: "viewfinder")
                    .font(.system(size: 80, weight: .thin))
                    .foregroundColor(themeAccent.opacity(0.6))
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
        }
    }

    private var permissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 46))
                .foregroundColor(themeAccent)
            Text("Camera access is required")
                .font(Theme.primaryText)
                .foregroundColor(.white)
            Text(camera.errorMessage ?? "Allow camera access in Settings, then return to Gymini.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .font(Theme.secondaryText)
        }
        .padding(30)
    }

    private var recommendationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("AI RECOMMENDATION", systemImage: "sparkles")
                .font(Theme.tertiaryText)
                .foregroundColor(themeAccent)
            Text("Squat station")
                .font(Theme.primaryText)
                .foregroundColor(.white)
            Text("Primary muscles: quads, glutes, hamstrings")
                .font(Theme.secondaryText)
                .foregroundColor(.white.opacity(0.75))
            Text("Suggested plan: 4 sets × 12 reps")
                .font(Theme.secondaryText)
                .foregroundColor(themeAccent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.black.opacity(0.8), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(themeAccent.opacity(0.4), lineWidth: 1)
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
                    .font(.system(size: 16, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundColor(.white)
            .background(themeAccent, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: themeAccent.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(!camera.permissionGranted || !camera.isRunning || isAnalyzing)
        .opacity(camera.permissionGranted && camera.isRunning && !isAnalyzing ? 1 : 0.45)
    }

    private var analyzingCard: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(themeAccent)
            VStack(alignment: .leading, spacing: 4) {
                Text("ANALYZING")
                    .font(Theme.tertiaryText)
                    .foregroundColor(themeAccent)
                Text("Identifying the equipment and target muscles…")
                    .font(Theme.secondaryText)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(.black.opacity(0.82), in: RoundedRectangle(cornerRadius: 18))
    }

    private func recommendationCard(for result: MachineAnalysisResponse) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("MACHINE ANALYSIS", systemImage: "sparkles")
                        .font(Theme.tertiaryText)
                        .foregroundColor(themeAccent)
                    Spacer()
                    Text("\(Int((min(max(result.confidence, 0), 1) * 100).rounded()))% match")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(.white.opacity(0.6))
                }

                Text(result.machineName)
                    .font(Theme.primaryText)
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("MAIN MUSCLES")
                        .font(Theme.tertiaryText)
                        .foregroundColor(.white.opacity(0.5))
                    Text(result.targetMuscles.joined(separator: " • "))
                        .font(Theme.secondaryText)
                        .foregroundColor(themeAccent)
                }

                Divider().overlay(.white.opacity(0.2))

                storyboardSection

                Divider().overlay(.white.opacity(0.2))

                instructionSection(title: "HOW TO USE IT", icon: "list.number", items: result.instructions)
                instructionSection(title: "SAFETY NOTES", icon: "exclamationmark.triangle", items: result.safetyNotes)

                Text("Suggested target: \(result.recommendedReps) reps")
                    .font(Theme.secondaryText)
                    .foregroundColor(themeAccent)
                Text(result.coachAdvice)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
        }
        .frame(maxWidth: .infinity)
        .frame(maxHeight: 430)
        .background(.black.opacity(0.84), in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(themeAccent.opacity(0.4), lineWidth: 1)
        }
    }

    private var storyboardSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("VISUAL INSTRUCTIONS", systemImage: "photo.on.rectangle.angled")
                .font(Theme.tertiaryText)
                .foregroundColor(.white.opacity(0.5))

            if let storyboardImage {
                ZStack(alignment: .bottom) {
                    Image(uiImage: storyboardImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .clipped()

                    HStack(spacing: 0) {
                        ForEach(1...3, id: \.self) { number in
                            Text("STEP \(number)")
                                .font(.caption2.weight(.bold))
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
                        .stroke(themeAccent.opacity(0.3), lineWidth: 1)
                }
            } else if isGeneratingStoryboard {
                VStack(spacing: 10) {
                    ProgressView()
                        .tint(themeAccent)
                    Text("Generating your 3-step visual guide…")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.78))
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(16 / 9, contentMode: .fit)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
            } else if storyboardUnavailable {
                Label(
                    "Visual guide is unavailable. Follow the written steps below.",
                    systemImage: "photo.badge.exclamationmark"
                )
                .font(.footnote)
                .foregroundColor(.white.opacity(0.72))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private func instructionSection(title: String, icon: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(Theme.tertiaryText)
                .foregroundColor(.white.opacity(0.5))

            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold))
                        .foregroundColor(themeAccent)
                        .frame(width: 20, height: 20)
                        .background(themeAccent.opacity(0.14), in: Circle())
                    Text(item)
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.86))
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
        scanRequestID = UUID()
        storyboardRequestID = UUID()
        isAnalyzing = false
        statusMessage = "Center the machine inside the frame"
    }

    private func requestStoryboard(for result: MachineAnalysisResponse) {
        let requestID = UUID()
        storyboardRequestID = requestID
        storyboardImage = nil
        storyboardUnavailable = false
        isGeneratingStoryboard = true

        LLMNetworkManager.shared.generateMachineInstructionStoryboard(
            machineName: result.machineName,
            instructions: result.instructions
        ) { response in
            guard storyboardRequestID == requestID else { return }

            withAnimation(.easeInOut(duration: 0.25)) {
                isGeneratingStoryboard = false
                switch response {
                case .success(let imageData):
                    if let image = UIImage(data: imageData) {
                        storyboardImage = image
                    } else {
                        storyboardUnavailable = true
                    }
                case .failure:
                    storyboardUnavailable = true
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
