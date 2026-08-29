import SwiftUI

class HealthStateManager: ObservableObject {
    static let shared = HealthStateManager()
    
    @Published var starRating: Int = 0
    @Published var selectedMuscle: String = "Chest"
    
    func statusText() -> String {
        switch starRating {
        case 5: return "Sung sức"
        case 4: return "Ổn định"
        case 3: return "Hơi mỏi"
        case 1, 2: return "Cần phục hồi"
        default: return "Chưa đánh giá"
        }
    }
    
    func statusColor(for scheme: ColorScheme) -> Color {
        switch starRating {
        case 5: return Theme.secondaryAccent(for: scheme) // Cyber Cyan / Green
        case 4: return Theme.secondaryAccent(for: scheme).opacity(0.8)
        case 3: return .yellow
        case 1, 2: return Theme.primaryAccent(for: scheme) // Neon Red / Crimson
        default: return .gray
        }
    }
}
