import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showScanMachine = false
    @State private var showTracking = false
    
    // Check-in State
    @StateObject private var healthState = HealthStateManager.shared
    @State private var isGenerating = false
    @State private var generatedWorkout: LLMNetworkManager.DailyWorkoutResponse?
    
    let muscleGroups = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Full Body"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header with Clock (Australia/Sydney Time)
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                TimelineView(.everyMinute) { context in
                                    Text(australiaTime(date: context.date))
                                        .font(Theme.tertiaryText)
                                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                }
                                Text("Ready to crush it?")
                                    .font(Theme.heroText)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        
                        // Daily Check-in Card
                        VStack(alignment: .leading, spacing: 24) {
                            Text("Daily Check-in")
                                .font(Theme.primaryText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What muscle group are you targeting today?")
                                    .font(Theme.secondaryText)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(muscleGroups, id: \.self) { muscle in
                                            Button(action: {
                                                withAnimation { healthState.selectedMuscle = muscle }
                                            }) {
                                                Text(muscle)
                                                    .font(Theme.secondaryText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(healthState.selectedMuscle == muscle ? Theme.primaryAccent(for: colorScheme) : Color.clear)
                                                    .foregroundColor(healthState.selectedMuscle == muscle ? .white : .primary)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(healthState.selectedMuscle == muscle ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("How is your physical condition today?")
                                    .font(Theme.secondaryText)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    HStack(spacing: 16) {
                                        ForEach(1...5, id: \.self) { index in
                                            Image(systemName: "star.fill")
                                                .font(.system(size: 32))
                                                .foregroundColor(starColor(for: index))
                                                .scaleEffect(healthState.starRating >= index ? 1.1 : 1.0)
                                                .onTapGesture {
                                                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                                    impactMed.impactOccurred()
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                                        healthState.starRating = index
                                                        generatedWorkout = nil // Reset when stars change
                                                    }
                                                }
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    if healthState.starRating > 0 {
                                        Text(healthState.statusText())
                                            .font(Theme.tertiaryText)
                                            .foregroundColor(healthState.statusColor(for: colorScheme))
                                    }
                                }
                            }
                            

                            
                            if healthState.starRating > 0 && generatedWorkout == nil {
                                Button(action: {
                                    withAnimation { isGenerating = true }
                                    LLMNetworkManager.shared.generateDailyWorkout(stars: healthState.starRating, targetMuscle: healthState.selectedMuscle) { result in
                                        withAnimation { isGenerating = false }
                                        if case .success(let response) = result {
                                            withAnimation { generatedWorkout = response }
                                        }
                                    }
                                }) {
                                    HStack {
                                        if isGenerating {
                                            ProgressView().tint(.white)
                                        } else {
                                            Text("Generate Workout")
                                        }
                                    }
                                    .metallicButton(scheme: colorScheme, isPrimary: true)
                                }
                                .padding(.top, 8)
                            }
                            
                            if let workout = generatedWorkout {
                                VStack(alignment: .leading, spacing: 16) {
                                    // 1. Detailed Workout
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(workout.title)
                                            .font(Theme.primaryText)
                                            .foregroundColor(workout.isActiveRecovery ? Color.orange : .primary)
                                        
                                        Text(workout.summary)
                                            .font(Theme.secondaryText)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Divider()
                                    
                                    // 2. Quick AI Suggestion
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Quick AI Suggestion")
                                            .font(Theme.tertiaryText)
                                            .foregroundColor(Theme.primaryAccent(for: colorScheme))
                                        
                                        Text(quickRecommendation)
                                            .font(Theme.secondaryText)
                                            .foregroundColor(.primary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(24)
                        .glassCard(cornerRadius: 24, scheme: colorScheme)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                withAnimation(.spring()) { showScanMachine = true }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 30))
                                    Text("Scan Machine")
                                        .font(Theme.secondaryText)
                                }
                                .metallicButton(scheme: colorScheme, isPrimary: true)
                            }
                            .fullScreenCover(isPresented: $showScanMachine) {
                                ScanMachineView()
                            }
                            
                            Button(action: {
                                withAnimation(.spring()) { showTracking = true }
                            }) {
                                VStack(spacing: 12) {
                                    Image(systemName: "figure.run")
                                        .font(.system(size: 30))
                                    Text("Start Tracking")
                                        .font(Theme.secondaryText)
                                }
                                .metallicButton(scheme: colorScheme, isPrimary: false)
                            }
                            .fullScreenCover(isPresented: $showTracking) {
                                ActiveTrackingView()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func australiaTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        formatter.dateFormat = "EEE, MMM d • h:mm a"
        return formatter.string(from: date)
    }
    
    private var quickRecommendation: String {
        let muscle = healthState.selectedMuscle
        let stars = healthState.starRating
        
        let intensity = stars >= 4 ? "Heavy & intense" : (stars == 3 ? "Moderate volume" : "Light recovery")
        let exercise: String
        switch muscle {
        case "Chest": exercise = "Bench Press & Flyes"
        case "Back": exercise = "Pull-ups & Rows"
        case "Legs": exercise = "Squats & Leg Press"
        case "Shoulders": exercise = "Overhead Press & Lateral Raises"
        case "Arms": exercise = "Bicep Curls & Tricep Extensions"
        case "Full Body": exercise = "Deadlifts & Burpees"
        default: exercise = "Compound movements"
        }
        
        return "\(intensity) \(exercise) focus today."
    }
    
    private func starColor(for index: Int) -> Color {
        if healthState.starRating >= index {
            return Theme.metallicGold
        }
        return Color.gray.opacity(0.3)
    }
}
