import SwiftUI

struct ScanMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasSeenScanTutorial") private var hasSeenScanTutorial = false
    @State private var showTutorial = true
    @State private var isScanning = false
    @State private var showResultSheet = false
    @State private var analysisResult: MachineAnalysisResponse?
    
    var body: some View {
        ZStack {
            Theme.AppBackground(scheme: colorScheme)
            
            // Mock Camera View
            VStack {
                Spacer()
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 150))
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme).opacity(0.2))
                    .blur(radius: 2)
                Spacer()
            }
            
            if isScanning {
                Color.black.opacity(0.5).edgesIgnoringSafeArea(.all)
                    .blur(radius: 30)
                    .transition(.opacity)
                
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(2)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Analyzing Machine...")
                        .font(Theme.secondaryText)
                        .foregroundColor(.white)
                }
            }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                if !isScanning {
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isScanning = true
                        }
                        
                        // Pass mock energy constraints to LLM (since EnergyManager is removed)
                        LLMNetworkManager.shared.scanMachine(imageData: Data(), currentEnergy: 100, fatiguedMuscles: []) { result in
                            withAnimation {
                                isScanning = false
                            }
                            switch result {
                            case .success(let response):
                                analysisResult = response
                                showResultSheet = true
                            case .failure(let error):
                                print("Error: \(error)")
                            }
                        }
                    }) {
                        Image(systemName: "largecircle.fill.circle")
                            .font(.system(size: 90))
                            .foregroundColor(Theme.primaryAccent(for: colorScheme))
                            .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.5), radius: 20, y: 0)
                    }
                    .padding(.bottom, 60)
                }
            }
            
            if !hasSeenScanTutorial {
                TutorialOverlayView(
                    steps: [
                        "Point the camera at the machine you want to use.",
                        "Tap capture for AI analysis and workout generation."
                    ],
                    isPresented: $showTutorial
                )
                .onChange(of: showTutorial) { newValue in
                    if !newValue {
                        hasSeenScanTutorial = true
                    }
                }
            }
        }
        .sheet(isPresented: $showResultSheet) {
            if let result = analysisResult {
                VStack(spacing: 24) {
                    Text(result.exerciseName)
                        .font(Theme.heroText)
                        .multilineTextAlignment(.center)
                    
                    VStack(spacing: 12) {
                        Text("Target Muscles")
                            .font(Theme.tertiaryText)
                            .foregroundColor(.secondary)
                        Text(result.targetMuscles.joined(separator: ", "))
                            .font(Theme.primaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard(cornerRadius: 16, scheme: colorScheme)
                    
                    VStack(spacing: 12) {
                        Text("Recommended Reps")
                            .font(Theme.tertiaryText)
                            .foregroundColor(.secondary)
                        Text("\(result.recommendedReps)")
                            .font(Theme.numberFont(size: 40))
                            .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .glassCard(cornerRadius: 16, scheme: colorScheme)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(Theme.primaryAccent(for: colorScheme))
                            Text("Coach says:")
                                .font(Theme.secondaryText)
                        }
                        Text(result.coachAdvice)
                            .font(Theme.secondaryText)
                            .foregroundColor(Theme.primaryAccent(for: colorScheme))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .glassCard(cornerRadius: 16, scheme: colorScheme)
                    
                    Spacer()
                    
                    Button(action: {
                        showResultSheet = false
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Start Workout")
                            .font(Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(Theme.primaryAccent(for: colorScheme))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 15, y: 8)
                    }
                    .padding(.bottom, 20)
                }
                .padding(24)
                .background(Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all))
                .presentationDetents([.large])
            }
        }
    }
}
