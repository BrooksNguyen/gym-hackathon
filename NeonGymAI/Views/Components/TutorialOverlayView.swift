import SwiftUI

struct TutorialOverlayView: View {
    @Environment(\.colorScheme) var colorScheme
    let steps: [String]
    @Binding var isPresented: Bool
    @State private var currentStepIndex = 0
    
    var body: some View {
        ZStack {
            // Dark transparent background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                // Tooltip Card
                VStack(spacing: 20) {
                    Text("Tutorial (Step \(currentStepIndex + 1)/\(steps.count))")
                        .font(Theme.primaryText)
                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    
                    Text(steps[currentStepIndex])
                        .font(Theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 16) {
                        Button(action: {
                            withAnimation {
                                isPresented = false
                            }
                        }) {
                            Text("Skip")
                                .font(Theme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .glassCard(cornerRadius: 12, scheme: colorScheme)
                        }
                        
                        Button(action: {
                            withAnimation {
                                if currentStepIndex < steps.count - 1 {
                                    currentStepIndex += 1
                                } else {
                                    isPresented = false
                                }
                            }
                        }) {
                            Text(currentStepIndex < steps.count - 1 ? "Continue" : "Got it")
                                .font(Theme.secondaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Theme.primaryAccent(for: colorScheme))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(24)
                .glassCard(cornerRadius: 24, scheme: colorScheme)
                .padding(24)
                
                Spacer()
            }
        }
        .transition(.opacity)
    }
}
