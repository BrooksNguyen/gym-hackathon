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
        withAnimation(.easeInOut) {
            hasCompletedOnboarding = true
        }
    }
}
