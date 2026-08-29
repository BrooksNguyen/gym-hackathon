import AVFoundation

class AudioCoachManager {
    static let shared = AudioCoachManager()
    private let synthesizer = AVSpeechSynthesizer()
    
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
