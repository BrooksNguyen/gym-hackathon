import SwiftUI

struct AICoachView: View {
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(text: "Hello! I am your AI Coach. How can I help you today?", isUser: false)
    ]
    
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
                            // TODO: Speech to text dictation
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .foregroundColor(Theme.neonCyan)
                        }
                        
                        Button(action: {
                            if !messageText.isEmpty {
                                messages.append(Message(text: messageText, isUser: true))
                                messageText = ""
                                // TODO: Call LLM Chat
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(Theme.neonCyan)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
