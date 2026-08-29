import Foundation

struct MachineAnalysisResponse: Codable {
    let exerciseName: String
    let targetMuscles: [String]
    let recommendedReps: Int
    let coachAdvice: String // Added field for contextual advice based on energy
}

class LLMNetworkManager {
    static let shared = LLMNetworkManager()
    
    enum LLMError: Error {
        case invalidURL
        case noData
        case decodingError(Error)
        case apiError(String)
    }
    
    func scanMachine(imageData: Data, currentEnergy: Int, fatiguedMuscles: [String], completion: @escaping (Result<MachineAnalysisResponse, Error>) -> Void) {
        let profile = ProfileManager.shared
        let scanMachinePrompt = """
        You are an expert AI Gym Coach. Analyze the provided image of a gym machine.
        
        CONTEXT:
        - User's Energy Level: \(currentEnergy)%
        - Fatigued Muscles: \(fatiguedMuscles.joined(separator: ", "))
        - User Goal: \(profile.goal)
        - User Weight: \(profile.weight)kg, Age: \(profile.age)
        
        RULES:
        1. High Energy (>80%): Recommend Progressive Overload. For \(profile.goal), adapt rep range (e.g., Cutting = 12-15 reps, Strength = 4-6 reps, Hypertrophy = 8-12 reps).
        2. Muscle Fatigue: If target muscles are in the fatigued list, explicitly suggest substituting the exercise.
        3. Low Energy (<40%): Trigger a "Deload" state. Explicitly recommend dropping the weight by 20% or stopping.
        
        Return a STRICT JSON response exactly matching this schema:
        {
          "exerciseName": "String",
          "targetMuscles": ["String"],
          "recommendedReps": 12,
          "coachAdvice": "String"
        }
        Do not output any markdown or additional text. Just the raw JSON.
        """
        
        // Mock implementation for Hackathon
        let advice = currentEnergy < 40 ? "Your energy is low (Deload state). Drop weight by 20%." : "Energy looks optimal! Since your goal is \(profile.goal), adapt your reps accordingly."
        
        let mockJSON = """
        {
          "exerciseName": "Leg Extension",
          "targetMuscles": ["Quadriceps"],
          "recommendedReps": 12,
          "coachAdvice": "\(advice)"
        }
        """.data(using: .utf8)!
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.5) {
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(MachineAnalysisResponse.self, from: mockJSON)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(LLMError.decodingError(error)))
                }
            }
        }
    }
    
    struct DailyWorkoutResponse: Codable {
        let title: String
        let summary: String
        let isActiveRecovery: Bool
    }
    
    func generateDailyWorkout(stars: Int, targetMuscle: String, completion: @escaping (Result<DailyWorkoutResponse, Error>) -> Void) {
        let profile = ProfileManager.shared
        // AI Logic based on Star Rating and Profile Goal
        var title = ""
        var summary = ""
        var isActiveRecovery = false
        
        // Adjust logic based on the user's goal
        let goalContext = profile.goal == "Cutting" ? "Focus on calorie burn and lower rest times." : (profile.goal == "Strength" ? "Focus on heavy loads and 3-5 min rests." : "Focus on hypertrophy (8-12 reps).")
        
        switch stars {
        case 5:
            title = "\(targetMuscle) - 100% Volume"
            summary = "You feel great! Time to push hard. \(goalContext)"
        case 4:
            title = "\(targetMuscle) - Slightly Fatigued"
            summary = "Maintain weight but drop 1-2 reps per set to manage fatigue. \(goalContext)"
        case 2, 3:
            title = "\(targetMuscle) - Deload Session"
            summary = "Aggressively scaling down. Drop working weight by 15-20%. Focus on form."
        case 1:
            title = "Stretching & Active Recovery"
            summary = "You are exhausted! Skip the weights today. 20 mins of mobility work."
            isActiveRecovery = true
        default:
            title = "\(targetMuscle) Workout"
            summary = "Standard workout routine. \(goalContext)"
        }
        
        let mockJSON = """
        {
          "title": "\(title)",
          "summary": "\(summary)",
          "isActiveRecovery": \(isActiveRecovery)
        }
        """.data(using: .utf8)!
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1.0) {
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(DailyWorkoutResponse.self, from: mockJSON)
                DispatchQueue.main.async {
                    completion(.success(result))
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(LLMError.decodingError(error)))
                }
            }
        }
    }
}
