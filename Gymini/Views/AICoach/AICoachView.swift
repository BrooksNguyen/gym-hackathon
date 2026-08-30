import SwiftUI
import FoundationModels

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var healthState = HealthStateManager.shared
    @StateObject private var profile = ProfileManager.shared
    @AppStorage("isAudioCoachEnabled") private var isAudioCoachEnabled = true
    @State private var messageText = ""
    @State private var isSending = false
    @State private var showingVoiceHint = false
    @State private var messages: [Message] = [
        Message(text: "Hello! I'm your AI Coach. Based on your profile, how can I help you today?", isUser: false)
    ]

    private let quickPrompts = ["How do I squat?", "Build me a leg day", "Check my form"]
    @State private var isAnimating = false
    @State private var isGenerating = false
    @State private var session: LanguageModelSession?
    
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
    
    private var systemPrompt: String {
        """
        You are an expert AI Gym Coach inside a fitness app called Gymini.
        
        USER PROFILE:
        - Name: \(profile.name.isEmpty ? "Athlete" : profile.name)
        - Age: \(profile.age)
        - Weight: \(profile.weight) kg
        - Height: \(profile.height) cm
        - BMI: \(String(format: "%.1f", bmi))
        - Goal: \(profile.goal)
        - Gender: \(profile.gender)
        - Sessions/week: \(profile.sessionsPerWeek)
        - Today's target muscle: \(healthState.selectedMuscle)
        - Current condition rating: \(healthState.starRating)/5
        
        RULES:
        - Give concise, actionable fitness advice (2-4 sentences max).
        - Personalize answers using the user's BMI, weight, goal, and condition.
        - For exercise form questions, give step-by-step cues.
        - For workout plans, tailor volume to their condition rating and goal.
        - Be encouraging but honest. Use a coach tone, not overly formal.
        - If asked about nutrition, factor in their BMI and goal.
        - Respond in the same language the user writes in.
        """
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                // Subtle shimmer glow when generating
                if isGenerating {
                    RoundedRectangle(cornerRadius: 40)
                        .strokeBorder(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.4),
                                    Color.gray.opacity(0.2),
                                    Color.white.opacity(0.5),
                                    Color.gray.opacity(0.2),
                                    Color.white.opacity(0.4)
                                ]),
                                center: .center,
                                angle: .degrees(isAnimating ? 360 : 0)
                            ),
                            lineWidth: 4
                        )
                        .blur(radius: 15)
                        .ignoresSafeArea()
                        .transition(.opacity)
                }
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Image(systemName: "apple.intelligence")
                            .font(.system(size: 18))
                            .foregroundColor(Theme.primaryAccent(for: colorScheme))
                        Text("Apple Intelligence")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                    .glassCard(cornerRadius: 16, scheme: colorScheme)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                    
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(messages) { message in
                                    HStack {
                                        if message.isUser {
                                            Spacer(minLength: 50)
                                            Text(message.text)
                                                .font(Theme.secondaryText)
                                                .padding()
                                                .background(Theme.primaryAccent(for: colorScheme))
                                                .foregroundColor(.white)
                                                .cornerRadius(20)
                                                .cornerRadius(4, corners: [.bottomRight])
                                        } else {
                                            HStack(alignment: .bottom) {
                                                // Metallic Silver Avatar
                                                ZStack {
                                                    Circle()
                                                        .fill(
                                                            LinearGradient(
                                                                gradient: Gradient(colors: [
                                                                    Color(red: 0.85, green: 0.87, blue: 0.90),
                                                                    Color(red: 0.65, green: 0.68, blue: 0.72),
                                                                    Color(red: 0.78, green: 0.80, blue: 0.84)
                                                                ]),
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            )
                                                        )
                                                        .frame(width: 32, height: 32)
                                                        .shadow(color: Color.gray.opacity(0.4), radius: 4)
                                                    
                                                    Image(systemName: "sparkles")
                                                        .font(.system(size: 14, weight: .bold))
                                                        .foregroundColor(Color(red: 0.3, green: 0.32, blue: 0.35))
                                                }
                                                .padding(.bottom, 8)
                                                
                                                Text(message.text)
                                                    .font(Theme.secondaryText)
                                                    .padding()
                                                    .glassCard(cornerRadius: 20, scheme: colorScheme)
                                            }
                                            Spacer(minLength: 50)
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
                                                    LinearGradient(
                                                        gradient: Gradient(colors: [
                                                            Color(red: 0.85, green: 0.87, blue: 0.90),
                                                            Color(red: 0.65, green: 0.68, blue: 0.72),
                                                            Color(red: 0.78, green: 0.80, blue: 0.84)
                                                        ]),
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 32, height: 32)
                                                .shadow(color: Color.gray.opacity(0.4), radius: 4)
                                            
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(Color(red: 0.3, green: 0.32, blue: 0.35))
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
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.gray.opacity(0.3)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .font(Theme.secondaryText)
                        
                        Button(action: {
                            isAudioCoachEnabled.toggle()
                            if !isAudioCoachEnabled {
                                AudioCoachManager.shared.stop()
                            }
                        }) {
                            Image(systemName: isAudioCoachEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .font(.title3)
                                .foregroundColor(isAudioCoachEnabled ? Theme.secondaryAccent(for: colorScheme) : .red.opacity(0.8))
                                .padding(16)
                                .glassCard(cornerRadius: 24, scheme: colorScheme)
                        }
                        
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
                                .background(Theme.primaryAccent(for: colorScheme))
                                .clipShape(Circle())
                                .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.3), radius: 8, y: 4)
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
            .onAppear {
                initializeSession()
                withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
    }
    
    private func initializeSession() {
        guard SystemLanguageModel.default.isAvailable else { return }
        session = LanguageModelSession(instructions: systemPrompt)
    }

    private func sendMessage() {
        let prompt = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !prompt.isEmpty, !isSending else { return }

        withAnimation {
            messages.append(Message(text: prompt, isUser: true))
        }
        messageText = ""
        isSending = true
        
        withAnimation {
            isGenerating = true
        }
        
        // Use Apple Intelligence Foundation Model
        Task {
            do {
                if session == nil {
                    initializeSession()
                }
                
                guard let activeSession = session else {
                    // Fallback if model not available
                    await MainActor.run {
                        let fallbackText = fallbackReply(for: prompt)
                        withAnimation {
                            messages.append(Message(text: fallbackText, isUser: false))
                            isGenerating = false
                            isSending = false
                        }
                        
                        let sentences = fallbackText.components(separatedBy: ". ")
                        let summary = sentences.prefix(2).joined(separator: ". ") + (sentences.count > 2 ? "." : "")
                        AudioCoachManager.shared.speak(text: summary)
                    }
                    return
                }
                
                let response = try await activeSession.respond(to: prompt)
                
                await MainActor.run {
                    withAnimation {
                        messages.append(Message(text: response.content, isUser: false))
                        isGenerating = false
                        isSending = false
                    }
                    
                    // Generate short summary (max 2 sentences) for Audio Coach to prevent latency
                    let sentences = response.content.components(separatedBy: ". ")
                    let summary = sentences.prefix(2).joined(separator: ". ") + (sentences.count > 2 ? "." : "")
                    AudioCoachManager.shared.speak(text: summary)
                }
            } catch {
                await MainActor.run {
                    let fallbackText = fallbackReply(for: prompt)
                    withAnimation {
                        messages.append(Message(text: fallbackText, isUser: false))
                        isGenerating = false
                        isSending = false
                    }
                    
                    let sentences = fallbackText.components(separatedBy: ". ")
                    let summary = sentences.prefix(2).joined(separator: ". ") + (sentences.count > 2 ? "." : "")
                    AudioCoachManager.shared.speak(text: summary)
                }
            }
        }
    }

    private func fallbackReply(for prompt: String) -> String {
        let lowercased = prompt.lowercased()
        if lowercased.contains("squat") || lowercased.contains("form") {
            return "For a strong squat: brace your core, keep your knees tracking over your toes, and drive through the mid-foot. I will watch your basic form in Tracking."
        }
        if lowercased.contains("leg") {
            return "Try 4 rounds: 12 squats, 10 reverse lunges per side, and a 30-second wall sit. Rest 60 seconds between rounds."
        }
        return "Apple Intelligence is not available on this device. Please try on a supported device (A17 Pro or M1+)."
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
