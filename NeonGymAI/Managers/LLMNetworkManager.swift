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
        let scanMachinePrompt = """
        You are an expert AI Gym Coach. Analyze the provided image of a gym machine.
        
        CONTEXT:
        - User's Energy Level: \(currentEnergy)%
        - Fatigued Muscles: \(fatiguedMuscles.joined(separator: ", "))
        
        RULES:
        1. High Energy (>80%): Recommend Progressive Overload (Increase weight/reps).
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
        let advice = currentEnergy < 40 ? "Your energy is low (Deload state). Drop weight by 20%." : "Energy looks optimal! Time for progressive overload."
        
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
}
