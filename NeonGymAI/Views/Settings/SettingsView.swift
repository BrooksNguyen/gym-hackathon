import SwiftUI

struct SettingsView: View {
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("isDarkMode") private var isDarkMode = true
    @State private var selectedLanguage = "English"
    @State private var audioCoachEnabled = true
    
    let languages = ["English", "Vietnamese"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.AppBackground(scheme: colorScheme)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Appearance Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Appearance")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 16) {
                                Toggle("Dark Mode", isOn: $isDarkMode)
                                    .font(Theme.primaryText)
                                    .tint(Theme.primaryAccent(for: colorScheme))
                            }
                            .padding()
                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                        }
                        
                        // Preferences Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preferences")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Language")
                                        .font(Theme.primaryText)
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
                                
                                Toggle("Audio Coach", isOn: $audioCoachEnabled)
                                    .font(Theme.primaryText)
                                    .tint(Theme.primaryAccent(for: colorScheme))
                            }
                            .padding()
                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                        }
                        
                        // Support Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Support & Debug")
                                .font(Theme.tertiaryText)
                                .foregroundColor(.secondary)
                            
                            VStack(spacing: 16) {
                                Button(action: {
                                    // Reset tooltips
                                    UserDefaults.standard.set(false, forKey: "hasSeenScanTutorial")
                                    UserDefaults.standard.set(false, forKey: "hasSeenTrackingTutorial")
                                    // Reset onboarding for testing
                                    UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
                                }) {
                                    HStack {
                                        Text("Reset All Tooltips & Onboarding")
                                            .font(Theme.primaryText)
                                        Spacer()
                                        Image(systemName: "arrow.counterclockwise")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(Theme.primaryAccent(for: colorScheme))
                                
                                Divider().background(Color.gray.opacity(0.2))
                                
                                Button(action: {
                                    // Action
                                }) {
                                    HStack {
                                        Text("Report / Feedback")
                                            .font(Theme.primaryText)
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .foregroundColor(Theme.primaryAccent(for: colorScheme))
                            }
                            .padding()
                            .glassCard(cornerRadius: 16, scheme: colorScheme)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
