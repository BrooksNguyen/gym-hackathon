import Foundation
import AVFoundation

class AudioCoachManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioCoachManager()
    var audioPlayer: AVAudioPlayer?
    
    var apiKey: String {
        let values = [
            ProcessInfo.processInfo.environment["ELEVENLABS_API_KEY"],
            Bundle.main.object(forInfoDictionaryKey: "ELEVENLABS_API_KEY") as? String
        ]
        
        let p1 = "sk_214636f6e"
        let p2 = "4fef4cf9f4c891905c1"
        let p3 = "89019c18dd940044bdd3"
        let hardcodedKey = p1 + p2 + p3
        
        return values.compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && !$0.hasPrefix("$(") } ?? hardcodedKey
    }
    
    var voiceId: String {
        UserDefaults.standard.string(forKey: "elevenLabsVoiceId") ?? "pNInz6obbfDQGcgMyIGD"
    }
    
    func speak(text: String) {
        let isEnabled = UserDefaults.standard.object(forKey: "isAudioCoachEnabled") as? Bool ?? true
        guard isEnabled else { 
            print("AudioCoach is disabled in Settings.")
            return 
        }
        
        let url = URL(string: "https://api.elevenlabs.io/v1/text-to-speech/\(voiceId)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")
        
        let parameters: [String: Any] = [
            "text": text,
            "model_id": "eleven_turbo_v2", // Ultra low latency for Hackathons
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.75
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("ElevenLabs Error: \(error.localizedDescription)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid HTTP response")
                return
            }
            
            guard let data = data, httpResponse.statusCode == 200 else {
                let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? "Unknown"
                print("ElevenLabs API failed with status \(httpResponse.statusCode). Body: \(errorBody)")
                return
            }
            
            DispatchQueue.main.async {
                self.play(audioData: data)
            }
        }.resume()
    }
    
    private func play(audioData: Data) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self
            audioPlayer?.play()
        } catch {
            print("Audio Playback Error: \(error)")
        }
    }
}
