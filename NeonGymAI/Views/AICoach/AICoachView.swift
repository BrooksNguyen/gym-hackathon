import SwiftUI

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var healthState = HealthStateManager.shared
    @StateObject private var profile = ProfileManager.shared
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showingVoiceHint = false
    @State private var messages: [Message] = [
        Message(text: "Hello! I'm your local AI Coach. Based on your current profile (Normal BMI, \(ProfileManager.shared.goal) goal), how can I help you today?", isUser: false)
    ]

    private let quickPrompts = ["How do I squat?", "Build me a leg day", "Check my form"]
    @State private var isAnimating = false
    @State private var isGenerating = false
    
    struct Message: Identifiable {
        let id = UUID()
        var text: String
        let isUser: Bool
    }
    
    private var bmi: Double {
        let heightInMeters = profile.height / 100
        guard heightInMeters > 0 else { return 0 }
        return profile.weight / (heightInMeters * heightInMeters)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                // Apple Intelligence Full Screen Edge Glow (Visible when generating)
                if isGenerating {
                    RoundedRectangle(cornerRadius: 40)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink, Color.orange, Color.blue]),
                                center: .center,
                                angle: .degrees(isAnimating ? 360 : 0)
                            ),
                            lineWidth: 8
                        )
                        .blur(radius: 20)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Intelligence Coach")
                                .font(.system(size: 20, weight: .bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        // Health Status Badge
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                                .shadow(color: Color.green.opacity(0.8), radius: 5)
                            Text("⚡ On-Device")
                                .font(Theme.tertiaryText)
                                .foregroundColor(Color.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .glassCard(cornerRadius: 12, scheme: colorScheme)
                    }
                    .padding()
                    .glassCard(cornerRadius: 16, scheme: colorScheme)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6), Color.pink.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                            .blur(radius: 0.5)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
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
                                                // Apple Intelligence Orb Avatar
                                                ZStack {
                                                    Circle()
                                                        .fill(
                                                            AngularGradient(
                                                                gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink, Color.orange, Color.blue]),
                                                                center: .center,
                                                                angle: .degrees(isAnimating ? 360 : 0)
                                                            )
                                                        )
                                                        .frame(width: 32, height: 32)
                                                        .shadow(color: Color.purple.opacity(0.5), radius: 5)
                                                    
                                                    Image(systemName: "sparkles")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                                .padding(.bottom, 8)
                                                
                                                Text(message.text)
                                                    .font(Theme.secondaryText)
                                                    .padding()
                                                    .glassCard(cornerRadius: 20, scheme: colorScheme)
                                                    .cornerRadius(4, corners: [.bottomLeft])
                                            }
                                            Spacer()
                                        }
                                    }
                                    .padding(.horizontal, 24)
                                    .transition(.scale.combined(with: .opacity).combined(with: .move(edge: message.isUser ? .trailing : .leading)))
                                    .id(message.id)
                                }
                                
                                if isGenerating {
                                    HStack(alignment: .bottom) {
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    AngularGradient(
                                                        gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink, Color.orange, Color.blue]),
                                                        center: .center,
                                                        angle: .degrees(isAnimating ? 360 : 0)
                                                    )
                                                )
                                                .frame(width: 32, height: 32)
                                                .shadow(color: Color.purple.opacity(0.5), radius: 5)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.white)
                                        }
                                        .padding(.bottom, 8)
                                        
                                        TypingIndicator()
                                            .padding()
                                            .frame(height: 48)
                                            .glassCard(cornerRadius: 20, scheme: colorScheme)
                                            .cornerRadius(4, corners: [.bottomLeft])
                                        Spacer()
                                    }
                                    .padding(.horizontal, 24)
                                    .transition(.opacity)
                                    .id("typingIndicator")
                                }
                            }
                            .padding(.top, 16)
                            .padding(.bottom, 20)
                        }
                        .onChange(of: messages.count) { _ in
                            withAnimation {
                                proxy.scrollTo(messages.last?.id, anchor: .bottom)
                            }
                        }
                        .onChange(of: isGenerating) { generating in
                            if generating {
                                withAnimation {
                                    proxy.scrollTo("typingIndicator", anchor: .bottom)
                                }
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
                    }
                    
                    // Context-Aware Prompts (Visible when no conversation history)
                    if messages.count == 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["💪 Chest workout plan", "📊 Nutrition for BMI \(String(format: "%.1f", bmi))", "🏃‍♂️ Fix Deadlift form"], id: \.self) { prompt in
                                    Button(action: {
                                        messageText = prompt
                                    }) {
                                        Text(prompt)
                                            .font(.system(size: 12, weight: .bold, design: .default))
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                                            .foregroundColor(.primary)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Theme.primaryAccent(for: colorScheme).opacity(0.3), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 8)
                        }
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    
                    // Input Bar
                    HStack(spacing: 12) {
                        TextField("Ask about workout/nutrition...", text: $messageText)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.4))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        isGenerating ? 
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink, Color.orange]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ) : LinearGradient(gradient: Gradient(colors: [Color.gray.opacity(0.3)]), startPoint: .leading, endPoint: .trailing),
                                        lineWidth: isGenerating ? 2 : 1
                                    )
                            )
                            .font(Theme.secondaryText)
                        
                        Button(action: {
                            showingVoiceHint = true
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                .padding(16)
                                .glassCard(cornerRadius: 24, scheme: colorScheme)
                        }
                        
                        Button(action: {
                            sendMessage()
                        }) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding(16)
                                .background(isGenerating ? Color.purple : Theme.primaryAccent(for: colorScheme))
                                .clipShape(Circle())
                                .shadow(color: (isGenerating ? Color.purple : Theme.primaryAccent(for: colorScheme)).opacity(0.4), radius: 10, y: 5)
                        }
                        .disabled(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                        .opacity(messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? 0.4 : 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
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

struct TypingIndicator: View {
    @State private var offset1: CGFloat = 0
    @State private var offset2: CGFloat = 0
    @State private var offset3: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(y: offset1)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0), value: offset1)
            
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(y: offset2)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.2), value: offset2)
            
            Circle()
                .fill(Color.white.opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(y: offset3)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.4), value: offset3)
        }
        .onAppear {
            offset1 = -5
            offset2 = -5
            offset3 = -5
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
