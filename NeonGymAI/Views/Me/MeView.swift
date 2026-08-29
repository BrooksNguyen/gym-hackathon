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
    
    // MARK: - BMI Calculation
    private var bmi: Double {
        let heightInMeters = profile.height / 100
        guard heightInMeters > 0 else { return 0 }
        return profile.weight / (heightInMeters * heightInMeters)
    }
    
    private var bmiStatus: (text: String, color: Color) {
        let value = bmi
        if value < 18.5 {
            return ("Underweight", .blue)
        } else if value < 25 {
            return ("Normal Weight", .green)
        } else if value < 30 {
            return ("Overweight", .yellow)
        } else {
            return ("Obese", .red)
        }
    }
    
    @State private var showBMIInfo = false
    
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
                        
                        // BMI & Body Metrics Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Health Overview")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 24) {
                                // Header: BMI Number & Status Tag
                                HStack(alignment: .firstTextBaseline) {
                                    Text("BMI")
                                        .font(Theme.secondaryText)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: { showBMIInfo.toggle() }) {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(Theme.primaryAccent(for: colorScheme))
                                    }
                                    .alert(isPresented: $showBMIInfo) {
                                        Alert(
                                            title: Text("About BMI"),
                                            message: Text("BMI is a general reference. If you have high muscle mass, this metric may not accurately reflect your body fat percentage."),
                                            dismissButton: .default(Text("Got it"))
                                        )
                                    }
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.1f", bmi))
                                        .font(Theme.heroText)
                                        .foregroundColor(.primary)
                                    
                                    Text(bmiStatus.text)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(bmiStatus.color.opacity(0.2))
                                        .foregroundColor(bmiStatus.color)
                                        .cornerRadius(8)
                                }
                                
                                // BMI Scale Bar
                                GeometryReader { geometry in
                                    let width = geometry.size.width
                                    let maxBMI: Double = 40.0
                                    let minBMI: Double = 15.0
                                    let clampedBMI = max(min(bmi, maxBMI), minBMI)
                                    // Calculate percentage (0.0 to 1.0)
                                    let percentage = (clampedBMI - minBMI) / (maxBMI - minBMI)
                                    
                                    VStack(alignment: .leading, spacing: 8) {
                                        // The marker
                                        VStack(spacing: 2) {
                                            Text("You")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.secondary)
                                            Image(systemName: "arrowtriangle.down.fill")
                                                .font(.caption2)
                                                .foregroundColor(.primary)
                                        }
                                        .offset(x: max(0, min(width * CGFloat(percentage) - 10, width - 20))) // Safe bounds
                                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: bmi)
                                        
                                        // The colored bar
                                        HStack(spacing: 0) {
                                            Rectangle().fill(Color.blue).frame(width: width * ((18.5 - 15.0) / (40.0 - 15.0)))
                                            Rectangle().fill(Color.green).frame(width: width * ((25.0 - 18.5) / (40.0 - 15.0)))
                                            Rectangle().fill(Color.yellow).frame(width: width * ((30.0 - 25.0) / (40.0 - 15.0)))
                                            Rectangle().fill(Color.red)
                                        }
                                        .frame(height: 12)
                                        .cornerRadius(6)
                                    }
                                }
                                .frame(height: 50)
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                // Quick Edit: Height & Weight
                                HStack(spacing: 0) {
                                    VStack(spacing: 0) {
                                        Text("Height (cm)")
                                            .font(Theme.secondaryText)
                                            .foregroundColor(.secondary)
                                        
                                        Picker("Height", selection: Binding(
                                            get: { Int(profile.height) },
                                            set: { profile.height = Double($0) }
                                        )) {
                                            ForEach(100...220, id: \.self) { h in
                                                Text("\(h)").tag(h)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 120)
                                    }
                                    
                                    Divider().background(Color.gray.opacity(0.1))
                                    
                                    VStack(spacing: 0) {
                                        Text("Weight (kg)")
                                            .font(Theme.secondaryText)
                                            .foregroundColor(.secondary)
                                        
                                        Picker("Weight", selection: Binding(
                                            get: { Int(profile.weight) },
                                            set: { profile.weight = Double($0) }
                                        )) {
                                            ForEach(40...150, id: \.self) { w in
                                                Text("\(w)").tag(w)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(height: 120)
                                    }
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
