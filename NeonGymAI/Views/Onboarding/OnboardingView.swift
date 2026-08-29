import SwiftUI

struct OnboardingView: View {
    @StateObject private var manager = OnboardingManager()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
            
            Group {
                switch manager.currentStep {
                case .metrics:
                    MetricsStepView(manager: manager)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                case .goals:
                    GoalsStepView(manager: manager)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                case .coachStatus:
                    CoachStatusStepView(manager: manager)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                case .uploadSchedule:
                    UploadScheduleStepView(manager: manager)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                case .aiIntro:
                    AIIntroStepView(manager: manager)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                }
            }
        }
    }
}
