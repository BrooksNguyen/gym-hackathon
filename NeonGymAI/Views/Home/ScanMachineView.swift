import SwiftUI

struct ScanMachineView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var isBlurred = false
    @State private var showBottomSheet = false
    
    var body: some View {
        ZStack {
            // Mock Camera View
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .ignoresSafeArea()
                .overlay(
                    VStack {
                        Image(systemName: "viewfinder")
                            .font(.system(size: 100, weight: .ultraLight))
                            .foregroundColor(Theme.primaryAccent(for: colorScheme).opacity(0.5))
                        Text("Align machine in frame")
                            .font(Theme.headline)
                            .foregroundColor(.white)
                            .padding(.top)
                    }
                )
                // Glassmorphism blur effect
                .blur(radius: isBlurred ? 20 : 0)
                .animation(.easeInOut(duration: 0.5), value: isBlurred)
            
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
                
                if !isBlurred {
                    Button(action: {
                        isBlurred = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            showBottomSheet = true
                        }
                    }) {
                        Circle()
                            .stroke(Color.white, lineWidth: 4)
                            .frame(width: 70, height: 70)
                            .overlay(
                                Circle().fill(Color.white).frame(width: 54, height: 54)
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .sheet(isPresented: $showBottomSheet, onDismiss: {
            presentationMode.wrappedValue.dismiss()
        }) {
            ScanResultSheet()
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }
}

struct ScanResultSheet: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            Theme.backgroundColor(for: colorScheme).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                Text("Machine Identified")
                    .font(Theme.caption)
                    .foregroundColor(Theme.secondaryAccent(for: colorScheme))
                    .textCase(.uppercase)
                
                Text("Leg Extension")
                    .font(Theme.largeTitle)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Target Muscles")
                        .font(Theme.headline)
                    Text("Quadriceps")
                        .font(Theme.body)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recommendation")
                        .font(Theme.headline)
                    Text("3 sets of 12 reps")
                        .font(Theme.body)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    // Start workout logic
                }) {
                    Text("Start Workout")
                        .font(Theme.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.primaryAccent(for: colorScheme))
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.bottom)
            }
            .padding(24)
        }
    }
}
