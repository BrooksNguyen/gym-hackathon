import Foundation
import SwiftUI

enum OnboardingStep {
    case metrics
    case goals
    case coachStatus
    case uploadSchedule
    case aiIntro
}

class OnboardingManager: ObservableObject {
    @Published var currentStep: OnboardingStep = .metrics
    
    // User Data
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var weight: Int = 70
    @Published var height: Int = 175
    
    @Published var selectedGoal: String = ""
    @Published var hasCoach: Bool? = nil
    
    let availableGoals = [
        "Tăng cơ - Hypertrophy",
        "Giảm mỡ - Cutting",
        "Tăng sức mạnh - Strength"
    ]
    
    func nextStep() {
        withAnimation(.easeInOut(duration: 0.5)) {
            switch currentStep {
            case .metrics:
                currentStep = .goals
            case .goals:
                currentStep = .coachStatus
            case .coachStatus:
                if hasCoach == true {
                    currentStep = .uploadSchedule
                } else if hasCoach == false {
                    currentStep = .aiIntro
                }
            default:
                break
            }
        }
    }
    
    func completeOnboarding() {
        // Save to AppStorage or standard UserDefaults
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
