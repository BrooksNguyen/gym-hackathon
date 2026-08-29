import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showScanMachine = false
    @State private var showTracking = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Header with Clock
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                TimelineView(.everyMinute) { context in
                                    Text(context.date.formatted(.dateTime.weekday().month().day().hour().minute()))
                                        .font(Theme.tertiaryText)
                                        .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                                }
                                Text("Ready to crush it?")
                                    .font(Theme.heroText)
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        
                        // Hero Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showScanMachine = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title2)
                                Text("Scan Machine")
                                    .font(Theme.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(Theme.primaryAccent(for: colorScheme))
                            )
                            .foregroundColor(.white)
                            .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 15, y: 8)
                        }
                        .fullScreenCover(isPresented: $showScanMachine) {
                            ScanMachineView()
                        }
                        
                        // Secondary Button
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showTracking = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .font(.title2)
                                Text("Start Tracking")
                                    .font(Theme.primaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(Color.clear)
                            .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                            .glassCard(cornerRadius: 24)
                        }
                        .fullScreenCover(isPresented: $showTracking) {
                            ActiveTrackingView()
                        }
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Recent Activity")
                                .font(Theme.primaryText)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 20) {
                                    ForEach(0..<5) { i in
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Squat")
                                                .font(Theme.secondaryText)
                                            Text("4 sets x 12 reps")
                                                .font(Theme.tertiaryText)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(20)
                                        .frame(width: 180, alignment: .leading)
                                        .glassCard(cornerRadius: 20)
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
