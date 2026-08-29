import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = true
    @AppStorage("notifications_enabled") private var notificationsEnabled = true
    @AppStorage("haptic_feedback") private var hapticFeedback = true
    @AppStorage("rest_timer_enabled") private var restTimerEnabled = true
    @AppStorage("units_metric") private var unitsMetric = true
    @State private var selectedLanguage = "English"
    @State private var showResetAlert = false
    @State private var showDeleteAlert = false
    
    let languages = ["English", "Vietnamese"]
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Appearance Section
                        settingsSection(title: "Appearance") {
                            Toggle("Dark Mode", isOn: $isDarkMode)
                                .font(Theme.secondaryText)
                                .tint(Theme.primaryAccent(for: colorScheme))
                        }
                        
                        // General Section
                        settingsSection(title: "General") {
                            HStack {
                                Text("Language")
                                    .font(Theme.secondaryText)
                                Spacer()
                                Picker("Language", selection: $selectedLanguage) {
                                    ForEach(languages, id: \.self) { language in
                                        Text(language).tag(language)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .tint(Theme.secondaryAccent(for: colorScheme))
                            }
                            
                            Divider().background(Color.gray.opacity(0.2))
                            
                            HStack {
                                Text("Units")
                                    .font(Theme.secondaryText)
                                Spacer()
                                Picker("Units", selection: $unitsMetric) {
                                    Text("Metric (kg/cm)").tag(true)
                                    Text("Imperial (lb/in)").tag(false)
                                }
                                .pickerStyle(MenuPickerStyle())
                                .tint(Theme.secondaryAccent(for: colorScheme))
                            }
                        }
                        
                        // Workout Section
                        settingsSection(title: "Workout") {
                            Toggle("Rest Timer", isOn: $restTimerEnabled)
                                .font(Theme.secondaryText)
                                .tint(Theme.primaryAccent(for: colorScheme))
                            
                            Divider().background(Color.gray.opacity(0.2))
                            
                            Toggle("Haptic Feedback", isOn: $hapticFeedback)
                                .font(Theme.secondaryText)
                                .tint(Theme.primaryAccent(for: colorScheme))
                        }
                        
                        // Notifications Section
                        settingsSection(title: "Notifications") {
                            Toggle("Push Notifications", isOn: $notificationsEnabled)
                                .font(Theme.secondaryText)
                                .tint(Theme.primaryAccent(for: colorScheme))
                        }
                        
                        // Data & Privacy Section
                        settingsSection(title: "Data & Privacy") {
                            Button(action: {
                                showResetAlert = true
                            }) {
                                HStack {
                                    Text("Reset All Data")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    Image(systemName: "arrow.counterclockwise")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .foregroundColor(.primary)
                            
                            Divider().background(Color.gray.opacity(0.2))
                            
                            Button(action: {
                                showDeleteAlert = true
                            }) {
                                HStack {
                                    Text("Delete All Workout History")
                                        .font(Theme.secondaryText)
                                    Spacer()
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.7))
                                }
                            }
                            .foregroundColor(.red.opacity(0.8))
                        }
                        
                        // About Section
                        settingsSection(title: "About") {
                            linkRow(title: "Privacy Policy", icon: "hand.raised")
                            Divider().background(Color.gray.opacity(0.2))
                            linkRow(title: "Terms of Service", icon: "doc.text")
                            Divider().background(Color.gray.opacity(0.2))
                            linkRow(title: "Rate on App Store", icon: "star")
                            Divider().background(Color.gray.opacity(0.2))
                            linkRow(title: "Share with Friends", icon: "square.and.arrow.up")
                            Divider().background(Color.gray.opacity(0.2))
                            HStack {
                                Text("Version")
                                    .font(Theme.secondaryText)
                                Spacer()
                                Text("\(appVersion) (\(buildNumber))")
                                    .font(Theme.secondaryText)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Text("Made with ❤️ for Hackathon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .alert("Reset All Data", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    UserDefaults.standard.set(false, forKey: "hasSeenScanTutorial")
                    UserDefaults.standard.set(false, forKey: "hasSeenTrackingTutorial")
                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                }
            } message: {
                Text("This will reset all tooltips, onboarding progress, and preferences. Your profile data will be kept.")
            }
            .alert("Delete Workout History", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    // Placeholder for actual deletion
                }
            } message: {
                Text("This will permanently delete all your workout history. This action cannot be undone.")
            }
        }
    }
    
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(Theme.tertiaryText)
                .foregroundColor(.secondary)
            
            VStack(spacing: 16) {
                content()
            }
            .padding()
            .glassCard(cornerRadius: 16, scheme: colorScheme)
        }
    }
    
    private func linkRow(title: String, icon: String) -> some View {
        Button(action: {}) {
            HStack {
                Text(title)
                    .font(Theme.secondaryText)
                Spacer()
                Image(systemName: icon)
                    .foregroundColor(.secondary)
            }
        }
        .foregroundColor(.primary)
    }
}
