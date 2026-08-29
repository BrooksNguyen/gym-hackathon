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
                                
                                ViewThatFits {
                                    // 1. Try to fit horizontally
                                    HStack(spacing: 16) {
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
                                                            generatedWorkout = nil
                                                        }
                                                    }
                                            }
                                        }
                                        
                                        if healthState.starRating > 0 {
                                            Text(healthState.statusText())
                                                .font(Theme.tertiaryText)
                                                .foregroundColor(healthState.statusColor(for: colorScheme))
                                        }
                                        Spacer()
                                    }
                                    
                                    // 2. Fallback to vertical if it doesn't fit
                                    VStack(alignment: .leading, spacing: 12) {
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
                                                            generatedWorkout = nil
                                                        }
                                                    }
                                            }
                                        }
                                        
                                        if healthState.starRating > 0 {
                                            Text(healthState.statusText())
                                                .font(Theme.tertiaryText)
                                                .foregroundColor(healthState.statusColor(for: colorScheme))
                                        }
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
                            } else if healthState.starRating == 0 {
                                Text("Rate your condition to generate today's AI plan...")
                                    .font(.system(size: 14, weight: .regular, design: .default))
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .padding(.top, 4)
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
                                            .foregroundColor(colorScheme == .dark ? Color(white: 0.85) : Color(white: 0.3)) // Better accessibility
                                    }
                                    
                                    Divider()
                                        .overlay(Color.primary.opacity(0.3))
                                    
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
                                .padding(20) // Better breathing room
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(colorScheme == .dark ? Color.black.opacity(0.25) : Color.white.opacity(0.6)) // Depth contrast
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.primary.opacity(0.1), lineWidth: 1)
                                )
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
                                VStack(spacing: 6) {
                                    ZStack {
                                        Image(systemName: "viewfinder")
                                            .font(.system(size: 34, weight: .light))
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 14))
                                    }
                                    .frame(height: 36)
                                    Text("Scan Machine")
                                        .font(Theme.secondaryText)
                                    Text("Find workouts for any machine")
                                        .font(.system(size: 10, weight: .bold, design: .default))
                                        .opacity(0.8)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(height: 28, alignment: .top)
                                }
                                .padding(.horizontal, 4)
                                .metallicButton(scheme: colorScheme, isPrimary: false, cornerRadius: 24)
                            }
                            .fullScreenCover(isPresented: $showScanMachine) {
                                ScanMachineView()
                            }
                            
                            Button(action: {
                                withAnimation(.spring()) { showTracking = true }
                            }) {
                                VStack(spacing: 6) {
                                    Image(systemName: "person.fill.viewfinder")
                                        .font(.system(size: 30))
                                        .frame(height: 36)
                                    Text("Live Assistant")
                                        .font(Theme.secondaryText)
                                    Text("Real-time rep & form tracking")
                                        .font(.system(size: 10, weight: .bold, design: .default))
                                        .opacity(0.8)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                        .frame(height: 28, alignment: .top)
                                }
                                .padding(.horizontal, 4)
                                .metallicButton(scheme: colorScheme, isPrimary: true, cornerRadius: 24)
                            }
                            .fullScreenCover(isPresented: $showTracking) {
                                ActiveTrackingView()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 80) // Added more safe area margin
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
