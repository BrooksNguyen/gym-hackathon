import SwiftUI

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var energyManager = EnergyManager.shared
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(text: "Hello! I am your AI Coach. How can I help you today?", isUser: false)
    ]
    
    // Breathing animation state for battery
    @State private var isBreathing = false
    
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
                    // Header with Health Battery
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Coach Monitor")
                                .font(Theme.primaryText)
                            Text("Health Status: \(energyManager.currentEnergyLevel >= 80 ? "Optimal" : (energyManager.currentEnergyLevel >= 40 ? "Fatigued" : "Exhausted"))")
                                .font(Theme.tertiaryText)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        // Energy Battery Ring
                        ZStack {
                            Circle()
                                .stroke(Color.gray.opacity(0.2), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: CGFloat(energyManager.currentEnergyLevel) / 100)
                                .stroke(energyManager.energyColor(for: colorScheme), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: energyManager.currentEnergyLevel)
                                .shadow(color: energyManager.energyColor(for: colorScheme).opacity(isBreathing ? 0.6 : 0.2), radius: isBreathing ? 10 : 3)
                            
                            Text("\(energyManager.currentEnergyLevel)%")
                                .font(Theme.numberFont(size: 12))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 40, height: 40)
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
                                    messageText = ""
                                }
                                // TODO: Call LLM Chat
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
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
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
