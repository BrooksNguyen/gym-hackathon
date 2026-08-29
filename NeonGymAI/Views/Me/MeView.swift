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
                Theme.AppBackground(scheme: colorScheme)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(Theme.primaryAccent(for: colorScheme))
                                .shadow(color: Theme.primaryAccent(for: colorScheme).opacity(0.4), radius: 15, y: 5)
                            
                            TextField("Name", text: $name)
                                .font(Theme.heroText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)
                        
                        // Basic Info Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Info")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Age")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    TextField("Age", text: $age)
                                        .keyboardType(.numberPad)
                                        .font(Theme.primaryText)
                                        .multilineTextAlignment(.trailing)
                                }
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                HStack {
                                    Text("Gender")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    Picker("Gender", selection: $selectedGender) {
                                        ForEach(Gender.allCases, id: \.self) { gender in
                                            Text(gender.rawValue).tag(gender)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .tint(Theme.primaryAccent(for: colorScheme))
                                }
                            }
                            .padding()
                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                        }
                        
                        // Body Metrics Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Body Metrics")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 24) {
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Height (cm)")
                                            .font(Theme.secondaryText)
                                        Spacer()
                                        Text("\(Int(height))")
                                            .font(Theme.numberFont(size: 24))
                                    }
                                    Slider(value: $height, in: 100...220, step: 1)
                                        .tint(Theme.secondaryAccent(for: colorScheme))
                                }
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("Weight (kg)")
                                            .font(Theme.secondaryText)
                                        Spacer()
                                        Text("\(Int(weight))")
                                            .font(Theme.numberFont(size: 24))
                                    }
                                    Slider(value: $weight, in: 40...150, step: 1)
                                        .tint(Theme.primaryAccent(for: colorScheme))
                                }
                            }
                            .padding()
                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                        }
                        
                        // Goals Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Goals")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            Picker("Goal", selection: $selectedGoal) {
                                ForEach(Goal.allCases, id: \.self) { goal in
                                    Text(goal.rawValue).tag(goal)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding()
                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
