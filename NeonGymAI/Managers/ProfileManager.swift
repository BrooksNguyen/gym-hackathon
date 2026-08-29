import SwiftUI

class ProfileManager: ObservableObject {
    static let shared = ProfileManager()
    
    @AppStorage("profile_name") var name: String = ""
    @AppStorage("profile_age") var age: Int = 25
    @AppStorage("profile_weight") var weight: Double = 70.0
    @AppStorage("profile_height") var height: Double = 175.0
    @AppStorage("profile_goal") var goal: String = "Hypertrophy"
    @AppStorage("profile_gender") var gender: String = "Male"
    @AppStorage("profile_sessions_per_week") var sessionsPerWeek: Int = 3
    
    private init() {}
}
