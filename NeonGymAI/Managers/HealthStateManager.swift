import SwiftUI

class HealthStateManager: ObservableObject {
    static let shared = HealthStateManager()
    
    @Published var starRating: Int = 0
    @Published var selectedMuscle: String = "Chest"
    
    func statusText() -> String {
        switch starRating {
        case 5: return "Peak Condition"
        case 4: return "Stable"
        case 3: return "Slightly Fatigued"
        case 1, 2: return "Needs Recovery"
        default: return "Unrated"
        }
    }
    
    func statusColor(for scheme: ColorScheme) -> Color {
        switch starRating {
        case 5: return Color.green // Peak condition
        case 4: return Color.green.opacity(0.7) // Good
        case 3: return Theme.metallicGold // Average
        case 1, 2: return Color.orange // High fatigue (Yellow/Orange)
        default: return .gray
        }
    }
}
