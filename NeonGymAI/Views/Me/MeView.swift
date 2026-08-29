import SwiftUI

struct MeView: View {
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var profile = ProfileManager.shared
    
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
    
    private var goalBinding: Binding<Goal> {
        Binding(
            get: { Goal(rawValue: profile.goal) ?? .hypertrophy },
            set: { profile.goal = $0.rawValue }
        )
    }
    
    private var genderBinding: Binding<Gender> {
        Binding(
            get: { Gender(rawValue: profile.gender) ?? .male },
            set: { profile.gender = $0.rawValue }
        )
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
                            
                            TextField("Name", text: $profile.name)
                                .font(Theme.heroText)
                                .multilineTextAlignment(.center)
                                .padding(12)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 40)
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
                                    TextField("Age", value: $profile.age, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(Theme.primaryText)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Theme.primaryAccent(for: colorScheme))
                                }
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                HStack {
                                    Text("Gender")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    Picker("Gender", selection: genderBinding) {
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
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Height (cm)")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    TextField("Height", value: $profile.height, format: .number)
                                        .keyboardType(.numberPad)
                                        .font(Theme.primaryText)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Theme.primaryAccent(for: colorScheme))
                                }
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                HStack {
                                    Text("Weight (kg)")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    TextField("Weight", value: $profile.weight, format: .number)
                                        .keyboardType(.decimalPad)
                                        .font(Theme.primaryText)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(Theme.primaryAccent(for: colorScheme))
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
                            
                            Picker("Goal", selection: goalBinding) {
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
