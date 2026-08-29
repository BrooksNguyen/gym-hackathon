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
        case 5: return Theme.secondaryAccent(for: scheme) // Cool Steel / Cobalt
        case 4: return Theme.metallicGold.opacity(0.8)
        case 3: return Theme.metallicGold
        case 1, 2: return Color.orange // Replaced Red with Metallic Copper/Orange vibe
        default: return .gray
        }
    }
}
