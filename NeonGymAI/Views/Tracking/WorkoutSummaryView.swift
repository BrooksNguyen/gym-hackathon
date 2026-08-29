import SwiftUI

struct WorkoutSummaryView: View {
    let reps: Int
    let exercise: String
    let onDone: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLoading = true
    @State private var summaryResponse: LLMNetworkManager.WorkoutSummaryAIResponse?
    
    var body: some View {
        ZStack {
            Theme.AppBackground(scheme: colorScheme)
            
            VStack(spacing: 30) {
                // header
                Text("WORKOUT COMPLETE")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.top, 40)
                
                if isLoading {
                    Spacer()
                    ProgressView("AI is analyzing your workout...")
                        .tint(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.secondary)
                    Spacer()
                } else if let response = summaryResponse {
                    // Form score (Most important)
                    VStack(spacing: 12) {
                        Text("Form Accuracy")
                            .font(Theme.secondaryText)
                            .foregroundColor(.secondary)
                        Text("\(response.formScore)%")
                            .font(.system(size: 80, weight: .heavy, design: .rounded))
                            .foregroundColor(Theme.neonGreen)
                            .shadow(color: Theme.neonGreen.opacity(0.3), radius: 10)
                        Text(response.coachFeedback)
                            .font(Theme.secondaryText)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical, 30)
                    .frame(maxWidth: .infinity)
                    .glassCard(cornerRadius: 24, scheme: colorScheme)
                    
                    // Details (Calories, Intensity, Reps)
                    HStack(spacing: 16) {
                        summaryCard(title: "Reps", value: "\(reps)", icon: "arrow.up.arrow.down", color: Theme.neonGreen)
                        summaryCard(title: "Calories", value: "\(response.caloriesBurned)", icon: "flame.fill", color: .orange)
                        summaryCard(title: "Intensity", value: response.intensity, icon: "bolt.fill", color: Theme.metallicGold)
                    }
                    
                    Spacer()
                }
                
                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.primaryAccent(for: colorScheme))
                        .cornerRadius(16)
                        .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.3), radius: 10, y: 5)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            generateSummary()
        }
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .glassCard(cornerRadius: 16, scheme: colorScheme)
    }
    
    private func generateSummary() {
        let profile = ProfileManager.shared
        let weight = profile.weight
        let heightInMeters = profile.height / 100.0
        let bmi = heightInMeters > 0 ? weight / (heightInMeters * heightInMeters) : 0
        
        LLMNetworkManager.shared.generateWorkoutSummary(
            exercise: exercise,
            reps: reps,
            weight: weight,
            height: profile.height,
            bmi: bmi
        ) { result in
            withAnimation {
                isLoading = false
                if case .success(let response) = result {
                    summaryResponse = response
                }
            }
        }
    }
}
