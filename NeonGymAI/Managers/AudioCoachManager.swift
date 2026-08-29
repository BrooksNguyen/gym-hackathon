import AVFoundation

class AudioCoachManager {
    static let shared = AudioCoachManager()
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    func speak(command: String) {
        let utterance = AVSpeechUtterance(string: command)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        synthesizer.speak(utterance)
    }
}
