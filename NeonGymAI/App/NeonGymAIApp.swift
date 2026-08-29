import SwiftUI

@main
struct NeonGymAIApp: App {
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                MainTabView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            } else {
                OnboardingView()
                    .preferredColorScheme(isDarkMode ? .dark : .light)
            }
        }
    }
}
