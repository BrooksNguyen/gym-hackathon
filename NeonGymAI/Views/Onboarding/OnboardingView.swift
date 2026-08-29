import SwiftUI

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.AppBackground(scheme: colorScheme)
            
            if manager.currentStep == 1 {
                MetricsInductionStep(manager: manager)
                    .transition(.opacity)
            } else if manager.currentStep == 2 {
                GoalsCommitmentStep(manager: manager)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Step 1: Basic Metrics (The Induction)
struct MetricsInductionStep: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Let's build your profile")
                .font(Theme.heroText)
                .padding(.top, 60)
            
            VStack(alignment: .leading, spacing: 16) {
                Text("What's your name?")
                    .font(Theme.secondaryText)
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                
                TextField("Nguyễn Phúc Bách", text: $manager.name)
                    .font(Theme.primaryText)
                    .padding(20)
                    .glassCard(cornerRadius: 16)
            }
            
            HStack(spacing: 20) {
                // Age Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Age")
                        .font(Theme.tertiaryText)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    Picker("Age", selection: $manager.age) {
                        ForEach(10..<100) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .glassCard(cornerRadius: 16)
                }
                
                // Weight Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Weight (kg)")
                        .font(Theme.tertiaryText)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    Picker("Weight", selection: $manager.weight) {
                        ForEach(30..<150) { w in
                            Text("\(w)").tag(w)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .glassCard(cornerRadius: 16)
                }
                
                // Height Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Height (cm)")
                        .font(Theme.tertiaryText)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    Picker("Height", selection: $manager.height) {
                        ForEach(100..<220) { h in
                            Text("\(h)").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                    .glassCard(cornerRadius: 16)
                }
            }
            
            Spacer()
            
            Button(action: {
                manager.nextStep()
            }) {
                Text("Next")
                    .font(Theme.primaryText)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Theme.primaryAccent(for: colorScheme))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 15, y: 8)
            }
            .padding(.bottom, 40)
            .disabled(manager.name.isEmpty)
            .opacity(manager.name.isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 2: Goals Commitment
struct GoalsCommitmentStep: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 40) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Chào mừng, \(manager.name.isEmpty ? "bạn" : manager.name)!")
                    .font(Theme.heroText)
                    .padding(.top, 60)
                
                Text("\(manager.name), mục tiêu hiện tại của bạn là gì?")
                    .font(Theme.secondaryText)
                    .foregroundColor(.secondary)
            }
            
            // Goals Chips
            VStack(spacing: 16) {
                ForEach(manager.availableGoals, id: \.self) { goal in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            manager.selectedGoal = goal
                        }
                    }) {
                        HStack {
                            Text(goal)
                                .font(Theme.primaryText)
                            Spacer()
                            if manager.selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Theme.primaryAccent(for: colorScheme))
                            }
                        }
                        .padding(20)
                        .glassCard(cornerRadius: 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(manager.selectedGoal == goal ? Theme.primaryAccent(for: colorScheme) : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(Theme.primaryAccent(for: colorScheme))
                }
            }
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Sessions per Week")
                    .font(Theme.tertiaryText)
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                
                HStack {
                    ForEach(1...7, id: \.self) { days in
                        Button(action: {
                            withAnimation(.spring()) {
                                manager.sessionsPerWeek = days
                            }
                        }) {
                            Text("\(days)")
                                .font(Theme.numberFont(size: 20))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(manager.sessionsPerWeek == days ? Theme.primaryAccent(for: colorScheme) : Color.clear)
                                .foregroundColor(manager.sessionsPerWeek == days ? .white : .primary)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .glassCard(cornerRadius: 16)
            }
            
            Spacer()
            
            if !manager.selectedGoal.isEmpty {
                Button(action: {
                    manager.completeOnboarding()
                }) {
                    Text("Bắt đầu hành trình")
                        .font(Theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 15, y: 8)
                }
                .padding(.bottom, 40)
            }
        }
        .padding(.horizontal, 24)
    }
}
