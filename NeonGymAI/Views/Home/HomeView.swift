import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var showScanMachine = false
    @State private var showTracking = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header with Clock
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                TimelineView(.everyMinute) { context in
                                    Text(context.date.formatted(.dateTime.weekday().month().day().hour().minute()))
                                        .font(Theme.caption)
                                        .foregroundColor(.secondary)
                                }
                                Text("Ready to crush it?")
                                    .font(Theme.largeTitle)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        
                        // Hero Button
                        Button(action: {
                            showScanMachine = true
                        }) {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                    .font(.title)
                                Text("Scan Machine")
                                    .font(Theme.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Theme.primaryAccent(for: colorScheme))
                            )
                            .foregroundColor(.white)
                            .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.3), radius: 10, y: 5)
                        }
                        .fullScreenCover(isPresented: $showScanMachine) {
                            ScanMachineView()
                        }
                        
                        // Secondary Button
                        Button(action: {
                            showTracking = true
                        }) {
                            HStack {
                                Image(systemName: "figure.run")
                                    .font(.title)
                                Text("Start Tracking")
                                    .font(Theme.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Theme.cardColor(for: colorScheme))
                            )
                            .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Theme.secondaryAccent(for: colorScheme), lineWidth: 2)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 10, y: 5)
                        }
                        .fullScreenCover(isPresented: $showTracking) {
                            ActiveTrackingView()
                        }
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Activity")
                                .font(Theme.title)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 16) {
                                    ForEach(0..<5) { i in
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Squat")
                                                .font(Theme.headline)
                                            Text("4 sets x 12 reps")
                                                .font(Theme.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding()
                                        .frame(width: 160, alignment: .leading)
                                        .background(Theme.cardColor(for: colorScheme))
                                        .cornerRadius(16)
                                        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
                                    }
                                }
                            }
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
}
