import SwiftUI

struct ActiveTrackingView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("hasSeenTrackingTutorial") private var hasSeenTrackingTutorial = false
    @State private var showTutorial = true
    @State private var reps = 0
    @State private var isAudioEnabled = true
    @State private var showFinishAlert = false
    @State private var navigateToAnalytics = false
    @Environment(\.presentationMode) var presentationMode
    
    // Breathing animation state
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            Theme.AppBackground(scheme: colorScheme)
            
            // Mock Camera View
            VStack {
                Spacer()
                Image(systemName: "figure.run")
                    .font(.system(size: 150))
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme).opacity(0.1))
                    .blur(radius: 2)
                Spacer()
            }
            
            // HUGE Transparent Rep Counter
            Text("\(reps)")
                .font(.system(size: 200, weight: .heavy, design: .rounded))
                .foregroundColor(Theme.primaryAccent(for: colorScheme).opacity(0.2))
                .blendMode(.overlay)
                .allowsHitTesting(false)
            
            VStack {
                // Top Bar
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                            .background(Circle().fill(Color.black.opacity(0.3)))
                    }
                    
                    Spacer()
                    
                    Text("CHECK FORM: SQUAT")
                        .font(Theme.primaryText)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .glassCard(cornerRadius: 12, scheme: colorScheme)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isAudioEnabled.toggle()
                        }
                    }) {
                        Image(systemName: isAudioEnabled ? "speaker.wave.3.fill" : "speaker.slash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isAudioEnabled ? Theme.primaryAccent(for: colorScheme) : .secondary)
                            .padding(12)
                            .glassCard(cornerRadius: 12, scheme: colorScheme)
                    }
                }
                .padding()
                
                Spacer()
                
                // Bottom Action Buttons
                HStack(spacing: 16) {
                    Button(action: {
                        // Take a break action
                    }) {
                        Text("Take a break")
                            .metallicButton(scheme: colorScheme, isPrimary: false) // Metallic Silver
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            navigateToAnalytics = true
                        }
                    }) {
                        Text("Finish")
                            .font(Theme.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red, Color.red.opacity(0.6)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(8) // Square look
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [Color.white.opacity(0.5), Color.black.opacity(0.3)]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.red.opacity(0.5), radius: 6, x: 0, y: 4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $navigateToAnalytics, onDismiss: {
            presentationMode.wrappedValue.dismiss() // Dismiss back to Home when Analytics finishes
        }) {
            AnalyticsDashboardView()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
            
            // Mock incrementing reps
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                if reps < 12 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        reps += 1
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
        .overlay(
            Group {
                if !hasSeenTrackingTutorial {
                    TutorialOverlayView(
                        steps: [
                            "Place your phone at knee or hip level.",
                            "Stand fully inside the frame for AI rep counting.",
                            "Tap Finish Session to save your results."
                        ],
                        isPresented: $showTutorial
                    )
                    .onChange(of: showTutorial) { newValue in
                        if !newValue {
                            hasSeenTrackingTutorial = true
                        }
                    }
                }
            }
        )
    }
}
