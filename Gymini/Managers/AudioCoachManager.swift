import Foundation
import AVFoundation

class AudioCoachManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = AudioCoachManager()
    var audioPlayer: AVAudioPlayer?
    
    let apiKey = "YOUR_ELEVENLABS_API_KEY"
    let voiceId = "pNInz6obbfDQGcgMyIGD" // Adam or Marcus
    
    func speak(text: String) {
        let isEnabled = UserDefaults.standard.bool(forKey: "isAudioCoachEnabled")
        guard isEnabled else { return }
        
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
            guard let data = data, error == nil else {
                print("ElevenLabs Error: \(error?.localizedDescription ?? "Unknown")")
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
