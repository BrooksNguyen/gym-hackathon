import SwiftUI

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var healthState = HealthStateManager.shared
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
                Theme.AppBackground(scheme: colorScheme)
                
                VStack(spacing: 0) {
                    // Header with Health Status Pill
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coach Monitor")
                                .font(Theme.primaryText)
                        }
                        
                        Spacer()
                        
                        // Health Status Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(healthState.statusColor(for: colorScheme))
                                .frame(width: 8, height: 8)
                                .shadow(color: healthState.statusColor(for: colorScheme).opacity(0.8), radius: 5)
                            Text(healthState.statusText())
                                .font(Theme.tertiaryText)
                                .foregroundColor(healthState.statusColor(for: colorScheme))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassCard(cornerRadius: 12)
                    }
                    .padding()
                    .glassCard(cornerRadius: 16)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    ScrollView {
                        VStack(spacing: 16) {
                            ForEach(messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        Text(message.text)
                                            .font(Theme.secondaryText)
                                            .padding()
                                            .background(Theme.primaryAccent(for: colorScheme))
                                            .foregroundColor(.white)
                                            .cornerRadius(20)
                                            .cornerRadius(4, corners: [.bottomRight])
                                    } else {
                                        HStack(alignment: .bottom) {
                                            Image(systemName: "sparkles")
                                                .font(.title3)
                                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                                .padding(.bottom, 8)
                                            
                                            Text(message.text)
                                                .font(Theme.secondaryText)
                                                .padding()
                                                .glassCard(cornerRadius: 20)
                                                .cornerRadius(4, corners: [.bottomLeft])
                                        }
                                        Spacer()
                                    }
                                }
                                .padding(.horizontal, 24)
                                .transition(.scale.combined(with: .opacity).combined(with: .move(edge: message.isUser ? .trailing : .leading)))
                            }
                        }
                        .padding(.top, 16)
                    }
                    
                    // Input Bar
                    HStack(spacing: 12) {
                        TextField("Ask about workout/nutrition...", text: $messageText)
                            .padding(16)
                            .glassCard(cornerRadius: 24)
                            .font(Theme.secondaryText)
                        
                        Button(action: {
                            // TODO: Speech to text dictation
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                .padding(16)
                                .glassCard(cornerRadius: 24)
                        }
                        
                        Button(action: {
                            if !messageText.isEmpty {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    messages.append(Message(text: messageText, isUser: true))
                                    let query = messageText
                                    messageText = ""
                                    
                                    // Simulated LLM Call with Context Append
                                    let contextString = "[System: User is currently '\(healthState.statusText())' with \(healthState.starRating) stars.]\n"
                                    print("Sending to LLM: \(contextString) \(query)")
                                    
                                    // Mock response
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                        withAnimation {
                                            if healthState.starRating == 1 {
                                                messages.append(Message(text: "I see you're needing recovery. Let's focus on stretching today instead.", isUser: false))
                                            } else {
                                                messages.append(Message(text: "Got it! Since you are '\(healthState.statusText())', let's adjust accordingly.", isUser: false))
                                            }
                                        }
                                    }
                                }
                            }
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(Theme.primaryAccent(for: colorScheme))
                                .clipShape(Circle())
                                .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 10, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// Extension to round specific corners for chat bubbles
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}
