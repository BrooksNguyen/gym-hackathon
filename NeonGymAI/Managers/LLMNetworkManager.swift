import Foundation

class LLMNetworkManager {
    static let shared = LLMNetworkManager()
    
    // System prompt for machine scanning
    let scanMachinePrompt = """
    You are an expert AI Gym Coach. Analyze the provided image of a gym machine.
    Return a STRICT JSON response with this schema:
    {
      "machine_name": "String",
      "primary_muscles": ["String"],
      "secondary_muscles": ["String"],
      "setup_instructions": "String",
      "recommended_sets_reps": "String"
    }
    Do not output any markdown or additional text. Just the raw JSON.
    """
    
    func scanMachine(imageData: Data, completion: @escaping (Result<String, Error>) -> Void) {
        // TODO: Implement network call to the LLM API (e.g. OpenAI GPT-4o Vision or Claude 3.5)
        // using URLSession and the system prompt above.
    }
}
