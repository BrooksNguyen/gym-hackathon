import SwiftUI

struct MeView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var name: String = "Nguyễn Phúc Bách"
    @State private var age: String = "25"
    @State private var height: Double = 175
    @State private var weight: Double = 70
    @State private var selectedGoal: Goal = .hypertrophy
    @State private var selectedGender: Gender = .male
    
    enum Goal: String, CaseIterable {
        case hypertrophy = "Hypertrophy"
        case cutting = "Cutting"
        case strength = "Strength"
    }
    
    enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Basic Info").font(Theme.tertiaryText).foregroundColor(Theme.secondaryAccent(for: colorScheme))) {
                        TextField("Name", text: $name)
                            .font(Theme.secondaryText)
                        TextField("Age", text: $age)
                            .keyboardType(.numberPad)
                            .font(Theme.secondaryText)
                        Picker("Gender", selection: $selectedGender) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Text(gender.rawValue).tag(gender)
                            }
                        }
                    }
                    .listRowBackground(Theme.cardColor(for: colorScheme))
                    
                    Section(header: Text("Body Metrics").font(Theme.tertiaryText).foregroundColor(Theme.secondaryAccent(for: colorScheme))) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("Height (cm)")
                                Spacer()
                                Text("\(Int(height))").font(Theme.primaryText)
                            }
                            Slider(value: $height, in: 100...220, step: 1)
                                .accentColor(Theme.primaryAccent(for: colorScheme))
                        }
                        .padding(.vertical, 4)
                        
                        VStack(spacing: 12) {
                            HStack {
                                Text("Weight (kg)")
                                Spacer()
                                Text("\(Int(weight))").font(Theme.primaryText)
                            }
                            Slider(value: $weight, in: 40...150, step: 1)
                                .accentColor(Theme.primaryAccent(for: colorScheme))
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.cardColor(for: colorScheme))
                    
                    Section(header: Text("Goals").font(Theme.tertiaryText).foregroundColor(Theme.secondaryAccent(for: colorScheme))) {
                        Picker("Goal", selection: $selectedGoal) {
                            ForEach(Goal.allCases, id: \.self) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Theme.cardColor(for: colorScheme))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
