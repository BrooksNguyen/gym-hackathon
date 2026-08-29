import SwiftUI

struct HomeView: View {
    private enum HomeFlow: String, Identifiable {
        case scan
        case tracking

        var id: String { rawValue }
    }

    @State private var presentedFlow: HomeFlow?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.trueBlack.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ready to crush it?")
                                .font(Theme.titleFont)
                                .foregroundColor(.white)
                            Text("Today's focus: Legs")
                                .font(Theme.digitalFont)
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Hero Button
                        Button(action: {
                            presentedFlow = .scan
                        }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title)
                                Text("Scan Machine")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.neonCyan, lineWidth: 2)
                                    .background(Theme.neonCyan.opacity(0.1))
                            )
                            .foregroundColor(Theme.neonCyan)
                            .shadow(color: Theme.neonCyan, radius: 10, x: 0, y: 0)
                        }
                        
                        // Secondary Button
                        Button(action: {
                            presentedFlow = .tracking
                        }) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .font(.title)
                                Text("Start Tracking")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Theme.neonGreen, lineWidth: 2)
                                    .background(Theme.neonGreen.opacity(0.1))
                            )
                            .foregroundColor(Theme.neonGreen)
                            .shadow(color: Theme.neonGreen, radius: 10, x: 0, y: 0)
                        }
                        
                        // Recent Activity
                        VStack(alignment: .leading) {
                            Text("Recent Activity")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(0..<5) { i in
                                        VStack(alignment: .leading) {
                                            Text("Squat")
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            Text("4 sets x 12 reps")
                                                .font(.subheadline)
                                                .foregroundColor(.gray)
                                        }
                                        .padding()
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Dashboard")
            .navigationBarHidden(true)
        }
        .fullScreenCover(item: $presentedFlow) { flow in
            switch flow {
            case .scan:
                MachineScanView {
                    presentedFlow = .tracking
                }
            case .tracking:
                WorkoutTrackingView()
            }
        }
    }
}
