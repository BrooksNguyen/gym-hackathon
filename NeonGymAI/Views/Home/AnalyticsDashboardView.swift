import SwiftUI

struct AnalyticsDashboardView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var appear = false
    
    var body: some View {
        ZStack {
            Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                Text("Session Completed")
                    .font(Theme.primaryText)
                    .padding(.top, 40)
                    .opacity(appear ? 1 : 0)
                
                // Mock Chart Area
                VStack(spacing: 16) {
                    Text("Workout Volume")
                        .font(Theme.secondaryText)
                    
                    HStack(alignment: .bottom, spacing: 20) {
                        ForEach([30, 50, 40, 80, 60], id: \.self) { height in
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Theme.primaryAccent(for: colorScheme))
                                .frame(width: 30, height: appear ? CGFloat(height) : 0)
                        }
                    }
                    .frame(height: 100)
                }
                .padding()
                .background(Theme.cardColor(for: colorScheme))
                .cornerRadius(16)
                .opacity(appear ? 1 : 0)
                
                Spacer()
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Back to Home")
                        .font(Theme.primaryText)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.secondaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                appear = true
            }
        }
    }
}
