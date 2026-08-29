import SwiftUI

// MARK: - Step 1: Basic Metrics
struct MetricsStepView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Let's get to know you")
                .font(Theme.largeTitle)
                .padding(.top, 60)
            
            VStack(alignment: .leading, spacing: 10) {
                Text("What's your name?")
                    .font(Theme.headline)
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                TextField("Nguyễn Phúc Bách", text: $manager.name)
                    .font(Theme.title)
                    .padding()
                    .background(Theme.cardColor(for: colorScheme))
                    .cornerRadius(12)
            }
            
            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Age")
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    Picker("Age", selection: $manager.age) {
                        ForEach(10..<100) { age in
                            Text("\(age)").tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
                
                VStack(alignment: .leading) {
                    Text("Weight (kg)")
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    Picker("Weight", selection: $manager.weight) {
                        ForEach(30..<150) { w in
                            Text("\(w)").tag(w)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
                
                VStack(alignment: .leading) {
                    Text("Height (cm)")
                        .font(Theme.caption)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    Picker("Height", selection: $manager.height) {
                        ForEach(100..<220) { h in
                            Text("\(h)").tag(h)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipped()
                }
            }
            
            Spacer()
            
            Button(action: {
                manager.nextStep()
            }) {
                Text("Continue")
                    .font(Theme.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryAccent(for: colorScheme))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.bottom, 40)
            .disabled(manager.name.isEmpty)
            .opacity(manager.name.isEmpty ? 0.5 : 1.0)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 2: Goals
struct GoalsStepView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Text("Chào mừng, \(manager.name.isEmpty ? "bạn" : manager.name)!")
                .font(Theme.largeTitle)
                .padding(.top, 60)
            
            Text("Mục tiêu của bạn là gì?")
                .font(Theme.headline)
                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
            
            VStack(spacing: 16) {
                ForEach(manager.availableGoals, id: \.self) { goal in
                    Button(action: {
                        manager.selectedGoal = goal
                    }) {
                        HStack {
                            Text(goal)
                                .font(Theme.body)
                            Spacer()
                            if manager.selectedGoal == goal {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(Theme.primaryAccent(for: colorScheme))
                            }
                        }
                        .padding()
                        .background(Theme.cardColor(for: colorScheme))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(manager.selectedGoal == goal ? Theme.primaryAccent(for: colorScheme) : Color.clear, lineWidth: 2)
                        )
                    }
                    .foregroundColor(Theme.primaryAccent(for: colorScheme))
                }
            }
            
            Spacer()
            
            if !manager.selectedGoal.isEmpty {
                Button(action: {
                    manager.nextStep()
                }) {
                    Text("Next")
                        .font(Theme.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.bottom, 40)
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 3: Coach Status
struct CoachStatusStepView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text("Bạn đã có Huấn luyện viên (Coach) chưa?")
                .font(Theme.title)
                .multilineTextAlignment(.center)
            
            VStack(spacing: 20) {
                Button(action: {
                    manager.hasCoach = true
                    manager.nextStep()
                }) {
                    Text("Rồi, tôi đã có Coach")
                        .font(Theme.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Theme.cardColor(for: colorScheme))
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
                }
                
                Button(action: {
                    manager.hasCoach = false
                    manager.nextStep()
                }) {
                    Text("Chưa, tôi tự tập")
                        .font(Theme.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.3), radius: 10, y: 5)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 4A: Upload Schedule
struct UploadScheduleStepView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Upload Your Schedule")
                .font(Theme.largeTitle)
                .padding(.top, 60)
            
            Text("Tuyệt vời! Hãy tải lên lịch tập từ Coach của bạn.")
                .font(Theme.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button(action: {
                // Mock upload action
            }) {
                VStack(spacing: 12) {
                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40))
                    Text("Tải file lịch tập")
                        .font(Theme.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
                .background(Theme.cardColor(for: colorScheme))
                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                )
            }
            .padding(.top, 20)
            
            Spacer()
            
            Button(action: {
                manager.completeOnboarding()
            }) {
                Text("Finish")
                    .font(Theme.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Theme.primaryAccent(for: colorScheme))
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Step 4B: AI Agent Intro
struct AIIntroStepView: View {
    @ObservedObject var manager: OnboardingManager
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(Theme.primaryAccent(for: colorScheme))
            
            Text("Để AI Coach lo!")
                .font(Theme.largeTitle)
            
            Text("Hãy chụp lại các máy tập xung quanh bạn, AI sẽ thiết kế bài tập dựa trên mục tiêu, \(manager.weight)kg và \(manager.height)cm của bạn.")
                .font(Theme.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
            
            Button(action: {
                // Complete onboarding and go to Home
                manager.completeOnboarding()
            }) {
                HStack {
                    Image(systemName: "camera.viewfinder")
                        .font(.title2)
                    Text("Scan Gym Equipment Now")
                        .font(Theme.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.primaryAccent(for: colorScheme))
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 15, y: 8)
            }
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 24)
    }
}
