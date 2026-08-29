import SwiftUI

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
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
                Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
                
                VStack {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .font(Theme.secondaryText)
                                            .padding()
                                            .background(Theme.primaryAccent(for: colorScheme))
                                            .foregroundColor(.white)
                                            .cornerRadius(16)
                                    } else {
                                        HStack(alignment: .bottom) {
                                            Image(systemName: "desktopcomputer")
                                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                            Text(message.text)
                                                .font(Theme.secondaryText)
                                                .padding()
                                                .background(Theme.secondaryAccent(for: colorScheme).opacity(0.2))
                                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                                .cornerRadius(16)
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal)
                                .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(.top)
                    }
                    
                    // Input Bar
                    HStack {
                        TextField("Ask about workout/nutrition...", text: $messageText)
                            .padding(12)
                            .background(Theme.cardColor(for: colorScheme))
                            .cornerRadius(20)
                            .font(Theme.secondaryText)
                        
                        Button(action: {
                            // TODO: Speech to text dictation
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.title2)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                        }
                        
                        Button(action: {
                            if !messageText.isEmpty {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    messages.append(Message(text: messageText, isUser: true))
                                    messageText = ""
                                }
                                // TODO: Call LLM Chat
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title2)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
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
