import Foundation
import SwiftUI

class EnergyManager: ObservableObject {
    static let shared = EnergyManager()
    
    @Published var currentEnergyLevel: Int = 85 // Mock starting energy
    @Published var fatiguedMuscles: [String] = [] // e.g. ["Hamstrings"]
    
    func energyColor(for scheme: ColorScheme) -> Color {
        if currentEnergyLevel >= 80 {
            return Theme.secondaryAccent(for: scheme) // Cyan / Green
        } else if currentEnergyLevel >= 40 {
            return .orange // Warning Yellow/Orange
        } else {
            return Theme.primaryAccent(for: scheme) // Red
        }
    }
    
    func decreaseEnergy(by amount: Int) {
        currentEnergyLevel = max(0, currentEnergyLevel - amount)
    }
    
    func addFatiguedMuscle(_ muscle: String) {
        if !fatiguedMuscles.contains(muscle) {
            fatiguedMuscles.append(muscle)
        }
    }
}
