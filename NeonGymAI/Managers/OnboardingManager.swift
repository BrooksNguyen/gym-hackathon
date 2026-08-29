import SwiftUI

class OnboardingManager: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var weight: Int = 70
    @Published var height: Int = 175
    
    @Published var selectedGoal: String = ""
    @Published var sessionsPerWeek: Int = 3
    
    @Published var currentStep: Int = 1
    
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    let availableGoals = ["Hypertrophy", "Cutting", "Strength"]
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            currentStep += 1
        }
    }
    
    func completeOnboarding() {
        let profile = ProfileManager.shared
        profile.name = self.name
        profile.age = self.age
        profile.weight = Double(self.weight)
        profile.height = Double(self.height)
        profile.goal = self.selectedGoal
        profile.sessionsPerWeek = self.sessionsPerWeek
        
        withAnimation(.easeInOut) {
            hasCompletedOnboarding = true
        }
    }
}
