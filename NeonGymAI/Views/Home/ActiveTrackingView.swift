import SwiftUI

struct ActiveTrackingView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var repCount = 0
    @State private var formStatus = "Good Form"
    @State private var isGoodForm = true
    
    var body: some View {
        ZStack {
            // Mock Camera Feed
            Rectangle()
                .fill(Color.black)
                .ignoresSafeArea()
                .overlay(
                    // Mock Skeleton
                    Path { path in
                        path.move(to: CGPoint(x: 200, y: 300))
                        path.addLine(to: CGPoint(x: 200, y: 500))
                        path.addLine(to: CGPoint(x: 250, y: 650))
                    }
                    .stroke(isGoodForm ? Theme.secondaryAccent(for: .dark) : Theme.primaryAccent(for: .dark), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
                    .shadow(color: isGoodForm ? Theme.secondaryAccent(for: .dark) : Theme.primaryAccent(for: .dark), radius: 10)
                )
            
            VStack {
                // Floating Metrics Card
                HStack(spacing: 40) {
                    VStack {
                        Text("REPS")
                            .font(Theme.caption)
                            .foregroundColor(.gray)
                        Text("\(repCount)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack {
                        Text("FORM")
                            .font(Theme.caption)
                            .foregroundColor(.gray)
                        Text(formStatus)
                            .font(Theme.headline)
                            .foregroundColor(isGoodForm ? Theme.secondaryAccent(for: .dark) : Theme.primaryAccent(for: .dark))
                    }
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 16)
                .background(.ultraThinMaterial)
                .cornerRadius(24)
                .padding(.top, 40)
                
                Spacer()
                
                // Finish Session Pill
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Finish Session")
                        .font(Theme.headline)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 16)
                        .background(Color.red) // Destructive action
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(color: Color.red.opacity(0.5), radius: 10, y: 5)
                }
                .padding(.bottom, 40)
            }
        }
    }
}
