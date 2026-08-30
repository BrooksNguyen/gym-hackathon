import Foundation

struct MachineAnalysisResponse: Codable {
    let machineName: String
    let confidence: Double
    let targetMuscles: [String]
    let instructions: [String]
    let safetyNotes: [String]
    let recommendedReps: Int
    let coachAdvice: String

    // Kept for compatibility with the older mock scan screen.
    var exerciseName: String { machineName }
}

class LLMNetworkManager {
    static let shared = LLMNetworkManager()

    private let machineScanModels = ["gemini-3.7-flash", "gemini-3.6-flash"]
    private let storyboardImageModel = "gemini-3.1-flash-image"
    private let maxRetriesPerModel = 1
    private let storyboardCache = MachineInstructionStoryboardCache()
    
    enum LLMError: LocalizedError {
        case invalidURL
        case noData
        case missingAPIKey
        case invalidResponse
        case invalidStoryboardSteps
        case decodingError(Error)
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "The Gemini scan URL is invalid."
            case .noData:
                return "No camera image was available for the scan."
            case .missingAPIKey:
                return "GEMINI_API_KEY is not configured for this app run."
            case .invalidResponse:
                return "Gemini returned an empty or unreadable scan result."
            case .invalidStoryboardSteps:
                return "Three instruction steps are required to create the visual guide."
            case .decodingError(let error):
                return "Gemini returned data the app could not read: \(error.localizedDescription)"
            case .apiError(let message):
                return message
            }
        }
    }
    
    func scanMachine(imageData: Data, currentEnergy: Int, fatiguedMuscles: [String], completion: @escaping (Result<MachineAnalysisResponse, Error>) -> Void) {
        let profile = ProfileManager.shared
        guard !imageData.isEmpty else {
            DispatchQueue.main.async { completion(.failure(LLMError.noData)) }
            return
        }

        guard let apiKey = geminiAPIKey else {
            DispatchQueue.main.async { completion(.failure(LLMError.missingAPIKey)) }
            return
        }

        let scanMachinePrompt = """
        You are an expert gym equipment identification coach. Analyze the image and identify the visible gym machine, not the person using it.

        CONTEXT:
        - User energy: \(currentEnergy)%
        - Fatigued muscles: \(fatiguedMuscles.isEmpty ? "none reported" : fatiguedMuscles.joined(separator: ", "))
        - User goal: \(profile.goal)

        RULES:
        1. Identify the equipment category, for example bench press, rowing machine, lat pulldown, leg press, cable machine, treadmill, or exercise bench.
        2. Prefer "Unknown gym machine" over guessing when the machine is not clearly visible.
        3. List the main muscle groups trained by that machine.
        4. Give exactly three concise instructions for adjusting and using the machine safely.
        5. Include safety notes about posture, load selection, and stopping if pain occurs.
        6. Recommend a reasonable rep target based on the user's goal and energy. If energy is below 40%, recommend a deload.
        7. Set confidence between 0 and 1, where 1 means the machine is clearly identifiable.

        Return only JSON matching the supplied schema. Do not include markdown or additional text.
        """

        let schema: [String: Any] = [
            "type": "object",
            "properties": [
                "machineName": ["type": "string"],
                "confidence": ["type": "number"],
                "targetMuscles": ["type": "array", "items": ["type": "string"]],
                "instructions": [
                    "type": "array",
                    "items": ["type": "string"]
                ],
                "safetyNotes": ["type": "array", "items": ["type": "string"]],
                "recommendedReps": ["type": "integer"],
                "coachAdvice": ["type": "string"]
            ],
            "required": [
                "machineName",
                "confidence",
                "targetMuscles",
                "instructions",
                "safetyNotes",
                "recommendedReps",
                "coachAdvice"
            ]
        ]

        performMachineScan(
            imageData: imageData,
            apiKey: apiKey,
            prompt: scanMachinePrompt,
            schema: schema,
            modelIndex: 0,
            attempt: 0,
            completion: completion
        )
    }

    func generateMachineInstructionStoryboard(
        machineName: String,
        instructions: [String],
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        if let cachedImage = storyboardCache.load(for: machineName) {
            DispatchQueue.main.async { completion(.success(cachedImage)) }
            return
        }

        guard let apiKey = geminiAPIKey else {
            DispatchQueue.main.async { completion(.failure(LLMError.missingAPIKey)) }
            return
        }

        let storyboardRequest = MachineInstructionStoryboardRequest(
            machineName: machineName,
            instructions: instructions
        )

        let payload: Data
        do {
            payload = try GeminiStoryboardAPIRequest.makePayload(
                model: storyboardImageModel,
                request: storyboardRequest
            )
        } catch GeminiStoryboardAPIRequest.RequestError.requiresThreeSteps {
            DispatchQueue.main.async { completion(.failure(LLMError.invalidStoryboardSteps)) }
            return
        } catch {
            DispatchQueue.main.async { completion(.failure(LLMError.decodingError(error))) }
            return
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/interactions") else {
            DispatchQueue.main.async { completion(.failure(LLMError.invalidURL)) }
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 75
        request.httpBody = payload
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2026-05-20", forHTTPHeaderField: "Api-Revision")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            let finish: (Result<Data, Error>) -> Void = { result in
                DispatchQueue.main.async { completion(result) }
            }

            if let error {
                finish(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                finish(.failure(LLMError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) }
                    ?? "No error details returned"
                finish(.failure(LLMError.apiError(
                    "Gemini image generation returned HTTP \(httpResponse.statusCode): \(message)"
                )))
                return
            }

            guard let data else {
                finish(.failure(LLMError.noData))
                return
            }

            do {
                let image = try GeminiStoryboardResponseParser.parse(data)
                try? self.storyboardCache.store(
                    image.data,
                    mimeType: image.mimeType,
                    for: machineName
                )
                finish(.success(image.data))
            } catch {
                finish(.failure(LLMError.decodingError(error)))
            }
        }.resume()
    }

    private func performMachineScan(
        imageData: Data,
        apiKey: String,
        prompt: String,
        schema: [String: Any],
        modelIndex: Int,
        attempt: Int,
        completion: @escaping (Result<MachineAnalysisResponse, Error>) -> Void
    ) {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/interactions") else {
            DispatchQueue.main.async { completion(.failure(LLMError.invalidURL)) }
            return
        }

        let model = machineScanModels[modelIndex]
        let requestBody: [String: Any] = [
            "model": model,
            "store": false,
            "input": [
                ["type": "text", "text": prompt],
                [
                    "type": "image",
                    "data": imageData.base64EncodedString(),
                    "mime_type": "image/jpeg"
                ]
            ],
            "response_format": [
                "type": "text",
                "mime_type": "application/json",
                "schema": schema
            ]
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 45
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2026-05-20", forHTTPHeaderField: "Api-Revision")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            DispatchQueue.main.async { completion(.failure(LLMError.decodingError(error))) }
            return
        }

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }

            let finish: (Result<MachineAnalysisResponse, Error>) -> Void = { result in
                DispatchQueue.main.async { completion(result) }
            }

            if let error {
                if self.isTransient(error: error) {
                    self.scheduleMachineScanRetry(
                        imageData: imageData,
                        apiKey: apiKey,
                        prompt: prompt,
                        schema: schema,
                        modelIndex: modelIndex,
                        attempt: attempt,
                        lastError: error,
                        completion: completion
                    )
                } else {
                    finish(.failure(error))
                }
                return
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                finish(.failure(LLMError.invalidResponse))
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                let message = data.flatMap { String(data: $0, encoding: .utf8) } ?? "No error details returned"
                let apiError = LLMError.apiError("Gemini returned HTTP \(httpResponse.statusCode): \(message)")
                if self.isTransient(statusCode: httpResponse.statusCode) {
                    self.scheduleMachineScanRetry(
                        imageData: imageData,
                        apiKey: apiKey,
                        prompt: prompt,
                        schema: schema,
                        modelIndex: modelIndex,
                        attempt: attempt,
                        lastError: apiError,
                        completion: completion
                    )
                } else {
                    finish(.failure(apiError))
                }
                return
            }

            guard let data else {
                finish(.failure(LLMError.noData))
                return
            }

            do {
                let envelope = try JSONDecoder().decode(GeminiInteractionResponse.self, from: data)
                guard let outputContents = envelope.steps
                    .first(where: { $0.type == "model_output" })?.content else {
                    finish(.failure(LLMError.invalidResponse))
                    return
                }

                let outputText = outputContents.compactMap(\.text)
                    .joined()
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard let jsonData = Self.jsonData(from: outputText) else {
                    finish(.failure(LLMError.invalidResponse))
                    return
                }

                let decodedResult = try JSONDecoder().decode(MachineAnalysisResponse.self, from: jsonData)
                let instructions = try MachineInstructionSteps.normalized(decodedResult.instructions)
                let result = MachineAnalysisResponse(
                    machineName: decodedResult.machineName,
                    confidence: decodedResult.confidence,
                    targetMuscles: decodedResult.targetMuscles,
                    instructions: instructions,
                    safetyNotes: decodedResult.safetyNotes,
                    recommendedReps: decodedResult.recommendedReps,
                    coachAdvice: decodedResult.coachAdvice
                )
                finish(.success(result))
            } catch {
                finish(.failure(LLMError.decodingError(error)))
            }
        }.resume()
    }

    private func scheduleMachineScanRetry(
        imageData: Data,
        apiKey: String,
        prompt: String,
        schema: [String: Any],
        modelIndex: Int,
        attempt: Int,
        lastError: Error,
        completion: @escaping (Result<MachineAnalysisResponse, Error>) -> Void
    ) {
        let nextModelIndex: Int
        let nextAttempt: Int
        let delay: TimeInterval

        if attempt < maxRetriesPerModel {
            nextModelIndex = modelIndex
            nextAttempt = attempt + 1
            delay = 1.5
        } else if modelIndex + 1 < machineScanModels.count {
            nextModelIndex = modelIndex + 1
            nextAttempt = 0
            delay = 0.5
        } else {
            DispatchQueue.main.async { completion(.failure(lastError)) }
            return
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.performMachineScan(
                imageData: imageData,
                apiKey: apiKey,
                prompt: prompt,
                schema: schema,
                modelIndex: nextModelIndex,
                attempt: nextAttempt,
                completion: completion
            )
        }
    }

    private func isTransient(error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        return [
            .timedOut,
            .cannotConnectToHost,
            .networkConnectionLost,
            .notConnectedToInternet
        ].contains(urlError.code)
    }

    private func isTransient(statusCode: Int) -> Bool {
        [429, 500, 502, 503, 504].contains(statusCode)
    }

    private var geminiAPIKey: String? {
        let values = [
            ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
            Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String
        ]

        return values
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.hasPrefix("$(") }
    }

    private static func jsonData(from text: String) -> Data? {
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              start <= end else {
            return nil
        }

        return String(text[start...end]).data(using: .utf8)
    }

    private struct GeminiInteractionResponse: Decodable {
        let steps: [GeminiStep]
    }

    private struct GeminiStep: Decodable {
        let type: String
        let content: [GeminiContent]?
    }

    private struct GeminiContent: Decodable {
        let type: String
        let text: String?
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
    
    struct WorkoutSummaryAIResponse: Codable {
        let caloriesBurned: Int
        let intensity: String
        let formScore: Int
        let coachFeedback: String
    }
    
    func generateWorkoutSummary(exercise: String, reps: Int, weight: Double, height: Double, bmi: Double, completion: @escaping (Result<WorkoutSummaryAIResponse, Error>) -> Void) {
        let baseCalories = Double(reps) * 1.5
        let weightFactor = weight / 70.0
        let estimatedCalories = Int(baseCalories * weightFactor)
        
        let intensity = reps >= 15 ? "High" : (reps >= 8 ? "Moderate" : "Low")
        let formScore = reps > 0 ? Int.random(in: 88...98) : 0
        
        // If reps == 0, skip API call and return immediately
        if reps == 0 {
            let fallbackResponse = WorkoutSummaryAIResponse(
                caloriesBurned: 0,
                intensity: "None",
                formScore: 0,
                coachFeedback: "It looks like you didn't do any reps. Don't worry, everyone starts somewhere! Ready to try again?"
            )
            DispatchQueue.main.async { completion(.success(fallbackResponse)) }
            return
        }
        
        guard let apiKey = geminiAPIKey else {
            DispatchQueue.main.async { completion(.failure(LLMError.missingAPIKey)) }
            return
        }
        
        let prompt = """
        You are a highly motivating AI fitness coach. The user just completed a set of \(exercise).
        - Reps completed: \(reps)
        - BMI: \(String(format: "%.1f", bmi))
        
        Analyze this mini-workout and provide a short, encouraging feedback message (max 2 sentences).
        Tailor it to their performance. Since this is a computer vision tracked workout, assume their form was mostly good but give a generic, helpful tip about \(exercise).
        
        Return ONLY valid JSON matching this exact schema:
        {
          "caloriesBurned": \(estimatedCalories),
          "intensity": "\(intensity)",
          "formScore": \(formScore),
          "coachFeedback": "Your encouraging 2-sentence feedback here"
        }
        """
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            DispatchQueue.main.async { completion(.failure(LLMError.invalidURL)) }
            return
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": prompt]]]
            ],
            "generationConfig": [
                "response_mime_type": "application/json"
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(LLMError.noData)) }
                return
            }
            
            do {
                // Gemini returns { "candidates": [ { "content": { "parts": [ { "text": "{ JSON }" } ] } } ] }
                struct GeminiResponse: Decodable {
                    struct Candidate: Decodable {
                        struct Content: Decodable {
                            struct Part: Decodable { let text: String }
                            let parts: [Part]
                        }
                        let content: Content
                    }
                    let candidates: [Candidate]
                }
                
                let geminiRes = try JSONDecoder().decode(GeminiResponse.self, from: data)
                guard let text = geminiRes.candidates.first?.content.parts.first?.text,
                      let jsonData = text.data(using: .utf8) else {
                    DispatchQueue.main.async { completion(.failure(LLMError.invalidResponse)) }
                    return
                }
                
                let result = try JSONDecoder().decode(WorkoutSummaryAIResponse.self, from: jsonData)
                DispatchQueue.main.async { completion(.success(result)) }
            } catch {
                DispatchQueue.main.async { completion(.failure(LLMError.decodingError(error))) }
            }
        }.resume()
    }
    
    func chat(prompt: String, systemInstruction: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let apiKey = geminiAPIKey else {
            DispatchQueue.main.async { completion(.failure(LLMError.missingAPIKey)) }
            return
        }
        
        let fullPrompt = "\(systemInstruction)\n\nUSER INPUT: \(prompt)"
        
        let requestBody: [String: Any] = [
            "contents": [
                ["parts": [["text": fullPrompt]]]
            ]
        ]
        
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=\(apiKey)") else {
            DispatchQueue.main.async { completion(.failure(LLMError.invalidURL)) }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: requestBody)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async { completion(.failure(LLMError.noData)) }
                return
            }
            
            do {
                struct GeminiResponse: Decodable {
                    struct Candidate: Decodable {
                        struct Content: Decodable {
                            struct Part: Decodable { let text: String }
                            let parts: [Part]
                        }
                        let content: Content
                    }
                    let candidates: [Candidate]
                }
                
                let geminiRes = try JSONDecoder().decode(GeminiResponse.self, from: data)
                if let text = geminiRes.candidates.first?.content.parts.first?.text {
                    DispatchQueue.main.async { completion(.success(text)) }
                } else {
                    DispatchQueue.main.async { completion(.failure(LLMError.invalidResponse)) }
                }
            } catch {
                DispatchQueue.main.async { completion(.failure(LLMError.decodingError(error))) }
            }
        }.resume()
    }
}
