import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showScanMachine = false
    @State private var showTracking = false
    
    // Check-in State
    @State private var selectedMuscle = "Chest"
    @State private var starRating = 0
    @State private var isGenerating = false
    @State private var generatedWorkout: LLMNetworkManager.DailyWorkoutResponse?
    
    let muscleGroups = ["Chest", "Back", "Legs", "Shoulders", "Arms", "Full Body"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header with Clock
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                TimelineView(.everyMinute) { context in
                                    Text(context.date.formatted(.dateTime.weekday().month().day().hour().minute()))
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
                                Text("Hôm nay bạn muốn tập nhóm cơ nào?")
                                    .font(Theme.secondaryText)
                                    .foregroundColor(.secondary)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(muscleGroups, id: \.self) { muscle in
                                            Button(action: {
                                                withAnimation { selectedMuscle = muscle }
                                            }) {
                                                Text(muscle)
                                                    .font(Theme.secondaryText)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 10)
                                                    .background(selectedMuscle == muscle ? Theme.primaryAccent(for: colorScheme) : Color.clear)
                                                    .foregroundColor(selectedMuscle == muscle ? .white : .primary)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 12)
                                                            .stroke(selectedMuscle == muscle ? Color.clear : Color.gray.opacity(0.3), lineWidth: 1)
                                                    )
                                                    .cornerRadius(12)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Thể lực hôm nay của bạn thế nào?")
                                    .font(Theme.secondaryText)
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 16) {
                                    ForEach(1...5, id: \.self) { index in
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(starColor(for: index))
                                            .scaleEffect(starRating >= index ? 1.1 : 1.0)
                                            .onTapGesture {
                                                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                                                impactMed.impactOccurred()
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                                    starRating = index
                                                    generatedWorkout = nil // Reset when stars change
                                                }
                                            }
                                    }
                                }
                            }
                            
                            if starRating > 0 && generatedWorkout == nil {
                                Button(action: {
                                    withAnimation { isGenerating = true }
                                    LLMNetworkManager.shared.generateDailyWorkout(stars: starRating, targetMuscle: selectedMuscle) { result in
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
                                    .font(Theme.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Theme.secondaryAccent(for: colorScheme))
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                                }
                                .padding(.top, 8)
                            }
                            
                            if let workout = generatedWorkout {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(workout.title)
                                        .font(Theme.primaryText)
                                        .foregroundColor(workout.isActiveRecovery ? Theme.primaryAccent(for: colorScheme) : .primary)
                                    
                                    Text(workout.summary)
                                        .font(Theme.secondaryText)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(12)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }
                        }
                        .padding(24)
                        .glassCard(cornerRadius: 24)
                        
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
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .background(Theme.primaryAccent(for: colorScheme))
                                .foregroundColor(.white)
                                .cornerRadius(20)
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
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                                .glassCard(cornerRadius: 20)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                            }
                            .fullScreenCover(isPresented: $showTracking) {
                                ActiveTrackingView()
                            }
                            // Block start tracking if it's active recovery? 
                            // Only a suggestion per user request, so button remains enabled.
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func starColor(for index: Int) -> Color {
        if starRating >= index {
            if starRating <= 2 {
                return Theme.primaryAccent(for: colorScheme) // Red/Orange
            } else if starRating <= 4 {
                return .yellow
            } else {
                return Theme.secondaryAccent(for: colorScheme) // Cyan/Green
            }
        }
        return Color.gray.opacity(0.3)
    }
}
