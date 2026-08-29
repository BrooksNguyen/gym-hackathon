import SwiftUI

struct ActiveTrackingView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var energyManager = EnergyManager.shared
    @State private var reps = 0
    @State private var showFinishAlert = false
    @State private var navigateToAnalytics = false
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
            
            // Mock Camera View
            VStack {
                Spacer()
                Image(systemName: "figure.run")
                    .font(.system(size: 150))
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme).opacity(0.3))
                Spacer()
            }
            
            VStack {
                // Floating Metrics Card
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("SQUAT")
                            .font(Theme.tertiaryText)
                            .foregroundColor(.secondary)
                        Text("\(reps) Reps")
                            .font(Theme.numberFont(size: 32))
                            .foregroundColor(.primary)
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
                .background(.ultraThinMaterial)
                .cornerRadius(20)
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
                        .padding()
                        .background(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 10, y: 5)
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
            // Mock incrementing reps
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                if reps < 12 {
                    reps += 1
                    energyManager.decreaseEnergy(by: 2)
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
