import SwiftUI

struct AICoachView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var healthState = HealthStateManager.shared
    @State private var messageText = ""
    @State private var messages: [Message] = [
        Message(text: "Hello! I am your AI Coach. How can I help you today?", isUser: false)
    ]
    @State private var isAnimating = false
    @State private var isGenerating = false
    
    struct Message: Identifiable {
        let id = UUID()
        let text: String
        let isUser: Bool
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
                                .font(Theme.primaryText)
                                .overlay(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.blue, Color.purple, Color.pink]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    .mask(Text("Apple Intelligence Coach").font(Theme.primaryText))
                                )
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
                        .glassCard(cornerRadius: 12, scheme: colorScheme)
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
                        }
                    }
                    
                    // Context-Aware Prompts (Visible when no conversation history)
                    if messages.count == 1 {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(["💪 Tạo lịch tập ngực", "📊 Dinh dưỡng cho BMI 23.5", "🏃‍♂️ Mẹo fix form Deadlift"], id: \.self) { prompt in
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
                            // TODO: Speech to text dictation
                        }) {
                            Image(systemName: "mic.fill")
                                .font(.title3)
                                .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                .padding(16)
                                .glassCard(cornerRadius: 24, scheme: colorScheme)
                        }
                        
                        Button(action: {
                            if !messageText.isEmpty {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    messages.append(Message(text: messageText, isUser: true))
                                    let query = messageText
                                    messageText = ""
                                    isGenerating = true
                                    
                                    // Mock User Profile
                                    let age = 24
                                    let gender = "Male"
                                    let bmi = 23.5
                                    let goal = "Hypertrophy"
                                    let todayTargetMuscle = healthState.selectedMuscle
                                    
                                    // System Prompt Injection
                                    let systemPrompt = """
                                    You are Gymini AI Coach, an expert fitness assistant.
                                    User Profile:
                                    - Age: \(age), Gender: \(gender)
                                    - BMI: \(bmi) (Normal)
                                    - Goal: \(goal)
                                    - Today's Target: \(todayTargetMuscle)
                                    Provide concise, actionable workout advice based strictly on these metrics.
                                    """
                                    print("Sending to Local SLM Model:\n\(systemPrompt)\nUser Query: \(query)")
                                    
                                    // Mock response delay for SLM Generation
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation {
                                            isGenerating = false
                                            if query.contains("Tạo lịch tập ngực") {
                                                messages.append(Message(text: "Dựa vào mục tiêu Hypertrophy và chỉ số BMI 23.5 của bạn, đây là lịch tập Ngực (Chest) hôm nay:\n1. Barbell Bench Press: 4x8-10\n2. Incline Dumbbell Press: 3x10-12\n3. Cable Crossovers: 3x15", isUser: false))
                                            } else {
                                                messages.append(Message(text: "Got it! Since you are focusing on \(todayTargetMuscle), let's adjust your plan to ensure optimal hypertrophy.", isUser: false))
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
                                .background(isGenerating ? Color.purple : Theme.primaryAccent(for: colorScheme))
                                .clipShape(Circle())
                                .shadow(color: (isGenerating ? Color.purple : Theme.primaryAccent(for: colorScheme)).opacity(0.4), radius: 10, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
        }
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
