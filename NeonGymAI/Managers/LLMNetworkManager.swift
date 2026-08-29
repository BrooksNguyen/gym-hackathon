import Foundation

struct MachineAnalysisResponse: Codable {
    let exerciseName: String
    let targetMuscles: [String]
    let recommendedReps: Int
}

class LLMNetworkManager {
    static let shared = LLMNetworkManager()
    
    let scanMachinePrompt = """
    You are an expert AI Gym Coach. Analyze the provided image of a gym machine.
    Return a STRICT JSON response exactly matching this schema:
    {
      "exerciseName": "String",
      "targetMuscles": ["String"],
      "recommendedReps": 12
    }
    Do not output any markdown or additional text. Just the raw JSON.
    """
    
    enum LLMError: Error {
        case invalidURL
        case noData
        case decodingError(Error)
        case apiError(String)
    }
    
    func scanMachine(imageData: Data, completion: @escaping (Result<MachineAnalysisResponse, Error>) -> Void) {
        // Mock implementation for Hackathon. In a real scenario, you'd send `imageData` 
        // to an endpoint like OpenAI Vision or Gemini Vision.
        let mockJSON = """
        {
          "exerciseName": "Leg Extension",
          "targetMuscles": ["Quadriceps"],
          "recommendedReps": 12
        }
        """.data(using: .utf8)!
        
        // Simulating network delay
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
