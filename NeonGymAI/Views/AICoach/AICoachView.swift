import SwiftUI

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var energyManager = EnergyManager.shared
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
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                            Circle()
                                .trim(from: 0, to: CGFloat(energyManager.currentEnergyLevel) / 100)
                                .stroke(energyManager.energyColor(for: colorScheme), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(), value: energyManager.currentEnergyLevel)
                            
                            Text("\(energyManager.currentEnergyLevel)%")
                                .font(Theme.numberFont(size: 12))
                                .foregroundColor(.primary)
                        }
                        .frame(width: 40, height: 40)
                    }
                    .padding()
                    .background(Theme.cardColor(for: colorScheme))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
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
