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
                Theme.backgroundColor(for: colorScheme).edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Appearance").font(Theme.tertiaryText).foregroundColor(Theme.secondaryAccent(for: colorScheme))) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .font(Theme.secondaryText)
                            .tint(Theme.primaryAccent(for: colorScheme))
                    }
                    .listRowBackground(Theme.cardColor(for: colorScheme))
                    
                    Section(header: Text("Preferences").font(Theme.tertiaryText).foregroundColor(Theme.secondaryAccent(for: colorScheme))) {
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).font(Theme.secondaryText).tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Toggle("Audio Coach", isOn: $audioCoachEnabled)
                            .font(Theme.secondaryText)
                            .tint(Theme.primaryAccent(for: colorScheme))
                    }
                    .listRowBackground(Theme.cardColor(for: colorScheme))
                    
                    Section(header: Text("Support").font(Theme.tertiaryText).foregroundColor(Theme.secondaryAccent(for: colorScheme))) {
                        Button("Report / Feedback") {
                            // Action
                        }
                        .font(Theme.secondaryText)
                        .foregroundColor(Theme.primaryAccent(for: colorScheme))
                    }
                    .listRowBackground(Theme.cardColor(for: colorScheme))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
