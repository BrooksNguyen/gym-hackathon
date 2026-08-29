import SwiftUI

struct ScanMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var energyManager = EnergyManager.shared
    @State private var isScanning = false
    @State private var showResultSheet = false
    @State private var analysisResult: MachineAnalysisResponse?
    
    var body: some View {
        ZStack {
            Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
            
            // Mock Camera View
            VStack {
                Spacer()
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 150))
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme).opacity(0.3))
                Spacer()
            }
            
            if isScanning {
                Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    .blur(radius: 20)
                    .transition(.opacity)
                
                ProgressView("Analyzing Machine...")
                    .foregroundColor(.white)
            }
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(Theme.secondaryAccent(for: colorScheme))
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
                        
                        // Pass energy constraints to LLM
                        LLMNetworkManager.shared.scanMachine(imageData: Data(), currentEnergy: energyManager.currentEnergyLevel, fatiguedMuscles: energyManager.fatiguedMuscles) { result in
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
                            .font(.system(size: 80))
                            .foregroundColor(Theme.primaryAccent(for: colorScheme))
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showResultSheet) {
            if let result = analysisResult {
                VStack(spacing: 20) {
                    Text(result.exerciseName)
                        .font(Theme.primaryText)
                    
                    Text("Targets: \(result.targetMuscles.joined(separator: ", "))")
                        .font(Theme.secondaryText)
                    
                    Text("Recommended Reps: \(result.recommendedReps)")
                        .font(Theme.tertiaryText)
                    
                    // Display Coach Advice directly derived from energy
                    Text("Coach says:")
                        .font(Theme.secondaryText)
                        .padding(.top)
                    Text(result.coachAdvice)
                        .font(Theme.secondaryText)
                        .foregroundColor(Theme.primaryAccent(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Theme.cardColor(for: colorScheme))
                        .cornerRadius(12)
                    
                    Button(action: {
                        showResultSheet = false
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Start Workout")
                            .font(Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.primaryAccent(for: colorScheme))
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.top, 20)
                }
                .padding(24)
                .presentationDetents([.medium, .large])
            }
        }
    }
}
