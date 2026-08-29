import SwiftUI

struct AICoachView: View {
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showingVoiceHint = false
    @State private var messages: [Message] = [
        Message(text: "Hello! I am your AI Coach. How can I help you today?", isUser: false)
    ]

    private let quickPrompts = ["How do I squat?", "Build me a leg day", "Check my form"]
    
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.trueBlack.edgesIgnoringSafeArea(.all)
                
                VStack {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .padding()
                                            .background(Color.gray.opacity(0.3))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                    } else {
                                        HStack(alignment: .bottom) {
                                            Image(systemName: "desktopcomputer")
                                                .foregroundColor(Theme.neonCyan)
                                            Text(message.text)
                                                .padding()
                                                .background(Theme.neonCyan.opacity(0.2))
                                                .foregroundColor(Theme.neonCyan)
                                                .cornerRadius(16)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                            }

                            if messages.count == 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("TRY ASKING")
                                        .font(.caption.weight(.bold))
                                        .tracking(1.2)
                                        .foregroundColor(.gray)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 8) {
                                            ForEach(quickPrompts, id: \.self) { prompt in
                                                Button(prompt) {
                                                    messageText = prompt
                                                    sendMessage()
                                                }
                                                .font(.caption.monospaced())
                                                .foregroundColor(Theme.neonCyan)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 9)
                                                .background(Theme.neonCyan.opacity(0.12), in: Capsule())
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Input Bar
                    HStack {
                        TextField("Ask about workout/nutrition...", text: $messageText)
                            .padding(12)
                            .background(Color.gray.opacity(0.2))
                            .cornerRadius(20)
                            .foregroundColor(.white)
                            .font(Theme.digitalFont)
                        
                        Button(action: {
                            showingVoiceHint = true
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .foregroundColor(Theme.neonCyan)
                        }
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(Theme.neonCyan)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                        .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.4 : 1)
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Voice input", isPresented: $showingVoiceHint) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Voice transcription will connect to the coach pipeline next. You can type a question for this demo.")
            }
        }
    }

    private func sendMessage() {
        let prompt = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isSending else { return }

        messages.append(Message(text: prompt, isUser: true))
        messageText = ""
        isSending = true

        // Keeps the UI demonstrable before Dev1's network client is connected.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            messages.append(Message(text: coachReply(for: prompt), isUser: false))
            isSending = false
        }
    }

    private func coachReply(for prompt: String) -> String {
        let lowercased = prompt.lowercased()
        if lowercased.contains("squat") || lowercased.contains("form") {
            return "For a strong squat: brace your core, keep your knees tracking over your toes, and drive through the mid-foot. I will watch your basic form in Tracking."
        }
        if lowercased.contains("leg") {
            return "Try 4 rounds: 12 squats, 10 reverse lunges per side, and a 30-second wall sit. Rest 60 seconds between rounds."
        }
        return "Start with a controlled tempo and stop if your form breaks down. Scan a machine or open Tracking when you are ready."
    }
}
