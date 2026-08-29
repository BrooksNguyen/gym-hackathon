import SwiftUI

struct WorkoutSummaryView: View {
    let reps: Int
    let exercise: String
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Theme.trueBlack.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // header
                Text("WORKOUT COMPLETE")
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.top, 40)
                
                // Form score (Most important)
                VStack(spacing: 10) {
                    Text("Form Accuracy")
                        .font(Theme.secondaryText)
                        .foregroundColor(.gray)
                    Text("92%")
                        .font(.system(size: 80, weight: .heavy, design: .rounded))
                        .foregroundColor(Theme.neonGreen)
                        .shadow(color: Theme.neonGreen.opacity(0.5), radius: 20)
                    Text("Excellent form throughout the session!")
                        .font(Theme.secondaryText)
                        .foregroundColor(.white)
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.05))
                .cornerRadius(24)
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                // Details (Calories, Intensity, Reps)
                HStack(spacing: 16) {
                    summaryCard(title: "Reps", value: "\(reps)", icon: "arrow.up.arrow.down", color: Theme.neonGreen)
                    summaryCard(title: "Calories", value: "320", icon: "flame.fill", color: .orange)
                    summaryCard(title: "Intensity", value: "High", icon: "bolt.fill", color: .yellow)
                }
                
                Spacer()
                
                Button {
                    onDone()
                } label: {
                    Text("Done")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Theme.neonGreen)
                        .cornerRadius(16)
                }
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func summaryCard(title: String, value: String, icon: String, color: Color = .white) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}
