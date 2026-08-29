import SwiftUI

struct ActiveTrackingView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var energyManager = EnergyManager.shared
    @State private var reps = 0
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
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme).opacity(0.2))
                    .blur(radius: 2)
                Spacer()
            }
            
            VStack {
                // Floating Metrics Card
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SQUAT")
                            .font(Theme.tertiaryText)
                            .foregroundColor(.secondary)
                        Text("\(reps) Reps")
                            .font(Theme.heroText)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Energy Battery Ring with Breathing glow
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 6)
                        Circle()
                            .trim(from: 0, to: CGFloat(energyManager.currentEnergyLevel) / 100)
                            .stroke(energyManager.energyColor(for: colorScheme), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.spring(), value: energyManager.currentEnergyLevel)
                            .shadow(color: energyManager.energyColor(for: colorScheme).opacity(isBreathing ? 0.6 : 0.2), radius: isBreathing ? 15 : 5)
                        
                        Text("\(energyManager.currentEnergyLevel)%")
                            .font(Theme.numberFont(size: 14))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 50, height: 50)
                }
                .padding(24)
                .glassCard(cornerRadius: 24)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer()
                
                // Finish Session Button
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        navigateToAnalytics = true
                    }
                }) {
                    Text("Finish Session")
                        .font(Theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.5), radius: 15, y: 8)
                }
                .padding(.horizontal, 40)
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
                        energyManager.decreaseEnergy(by: 2)
                    }
                    if reps == 10 {
                        energyManager.addFatiguedMuscle("Quadriceps")
                    }
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}
