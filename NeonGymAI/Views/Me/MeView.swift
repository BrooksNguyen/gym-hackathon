import SwiftUI

struct MeView: View {
    @State private var name: String = "Nguyễn Phúc Bách"
    @State private var age: String = "25"
    @State private var height: Double = 175
    @State private var weight: Double = 70
    @State private var selectedGoal: Goal = .hypertrophy
    
    enum Goal: String, CaseIterable {
        case hypertrophy = "Hypertrophy"
        case cutting = "Cutting"
        case strength = "Strength"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.trueBlack.edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Basic Info").foregroundColor(Theme.neonCyan)) {
                        TextField("Name", text: $name)
                            .foregroundColor(.white)
                            .font(Theme.digitalFont)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .foregroundColor(.white)
                            .font(Theme.digitalFont)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    
                    Section(header: Text("Body Metrics").foregroundColor(Theme.neonCyan)) {
                        VStack {
                            HStack {
                                Text("Height (cm): \(Int(height))")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            Slider(value: $height, in: 100...220, step: 1)
                                .accentColor(Theme.neonCyan)
                        }
                        
                        VStack {
                            HStack {
                                Text("Weight (kg): \(Int(weight))")
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            Slider(value: $weight, in: 40...150, step: 1)
                                .accentColor(Theme.neonCyan)
                        }
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    
                    Section(header: Text("Goals").foregroundColor(Theme.neonCyan)) {
                        Picker("Goal", selection: $selectedGoal) {
                            ForEach(Goal.allCases, id: \.self) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}
