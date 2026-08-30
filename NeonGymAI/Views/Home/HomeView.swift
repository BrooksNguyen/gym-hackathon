import SwiftUI
import UIKit

struct HomeView: View {
    @Environment(\.colorScheme) private var colorScheme

    private enum HomeFlow: String, Identifiable {
        case scan
        case tracking

        var id: String { rawValue }
    }

    @StateObject private var healthState = HealthStateManager.shared
    @State private var presentedFlow: HomeFlow?
    @State private var isGenerating = false
    @State private var generatedWorkout: LLMNetworkManager.DailyWorkoutResponse?

    private let muscleGroups = ["Chest", "Back", "Legs", "Shoulders"]

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        dailyCheckIn
                        actionButtons
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 80)
                }
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $presentedFlow) { flow in
            switch flow {
            case .scan:
                MachineScanView {
                    presentedFlow = .tracking
                }
            case .tracking:
                WorkoutTrackingView()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            TimelineView(.everyMinute) { context in
                Text(australiaTime(date: context.date))
                    .font(Theme.tertiaryText)
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme))
            }

            Text("Ready to crush it?")
                .font(Theme.heroText)
                .foregroundColor(.primary)

            Text("Today's focus: \(healthState.selectedMuscle)")
                .font(Theme.secondaryText)
                .foregroundColor(.secondary)
        }
    }

    private var dailyCheckIn: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Daily Check-in")
                .font(Theme.primaryText)
                .foregroundColor(.primary)

            VStack(alignment: .leading, spacing: 12) {
                Text("What muscle group are you targeting today?")
                    .font(Theme.secondaryText)
                    .foregroundColor(.secondary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(muscleGroups, id: \.self) { muscle in
                            Button {
                                withAnimation {
                                    healthState.selectedMuscle = muscle
                                    generatedWorkout = nil
                                }
                            } label: {
                                Text(muscle)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(healthState.selectedMuscle == muscle ? .white : .primary)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        healthState.selectedMuscle == muscle
                                            ? Theme.primaryAccent(for: colorScheme)
                                            : Color.clear,
                                        in: Capsule()
                                    )
                                    .overlay {
                                        Capsule()
                                            .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                    }
                            }
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("How is your physical condition today?")
                    .font(Theme.secondaryText)
                    .foregroundColor(.secondary)

                HStack(spacing: 14) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                                healthState.starRating = index
                                generatedWorkout = nil
                            }
                        } label: {
                            Image(systemName: "star.fill")
                                .font(.system(size: 28))
                                .foregroundColor(starColor(for: index))
                                .scaleEffect(healthState.starRating >= index ? 1.1 : 1.0)
                        }
                        .buttonStyle(.plain)
                    }

                    if healthState.starRating > 0 {
                        Text(healthState.statusText())
                            .font(Theme.tertiaryText)
                            .foregroundColor(healthState.statusColor(for: colorScheme))
                    }
                }
            }

            if healthState.starRating > 0 && generatedWorkout == nil {
                Button {
                    generateWorkout()
                } label: {
                    HStack {
                        if isGenerating {
                            ProgressView().tint(.white)
                        } else {
                            Text("Generate Workout")
                        }
                    }
                    .metallicButton(scheme: colorScheme, isPrimary: true)
                }
                .disabled(isGenerating)
            } else if healthState.starRating == 0 {
                Text("Rate your condition to generate today's AI plan...")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .italic()
            }

            if let workout = generatedWorkout {
                VStack(alignment: .leading, spacing: 10) {
                    Text(workout.title)
                        .font(Theme.primaryText)
                        .foregroundColor(workout.isActiveRecovery ? .orange : .primary)

                    Text(workout.summary)
                        .font(Theme.secondaryText)
                        .foregroundColor(.primary)

                    Divider()

                    Text("Quick AI Suggestion")
                        .font(Theme.tertiaryText)
                        .foregroundColor(Theme.primaryAccent(for: colorScheme))

                    Text(quickRecommendation)
                        .font(Theme.secondaryText)
                        .foregroundColor(.primary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.05), in: RoundedRectangle(cornerRadius: 14))
            }
        }
        .padding(20)
        .glassCard(cornerRadius: 24, scheme: colorScheme)
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            // Left Card: Scan Machine
            Button {
                presentedFlow = .scan
            } label: {
                VStack(spacing: 12) {
                    ZStack {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 32, weight: .light))
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundColor(.white)
                    
                    VStack(spacing: 4) {
                        Text("Machine Scanner")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Text("Find workouts for any machine")
                            .font(.system(size: 10))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .glassCard(cornerRadius: 20, scheme: colorScheme)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            // Right Card: Live Assistant
            Button {
                presentedFlow = .tracking
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "person.fill.viewfinder")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 4) {
                        Text("Live Assistant")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        Text("Real-time rep & form tracking")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .background(Theme.primaryAccent(for: colorScheme))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.3), radius: 10, y: 5)
            }
            .buttonStyle(.plain)
        }
    }

    private func generateWorkout() {
        isGenerating = true
        LLMNetworkManager.shared.generateDailyWorkout(
            stars: healthState.starRating,
            targetMuscle: healthState.selectedMuscle
        ) { result in
            withAnimation {
                isGenerating = false
                if case .success(let response) = result {
                    generatedWorkout = response
                }
            }
        }
    }

    private func australiaTime(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        formatter.dateFormat = "EEE, MMM d • h:mm a"
        return formatter.string(from: date)
    }

    private var quickRecommendation: String {
        let intensity = healthState.starRating >= 4
            ? "Heavy & intense"
            : healthState.starRating == 3 ? "Moderate volume" : "Light recovery"

        let exercise: String
        switch healthState.selectedMuscle {
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
        healthState.starRating >= index ? Theme.metallicGold : Color.gray.opacity(0.3)
    }
}
