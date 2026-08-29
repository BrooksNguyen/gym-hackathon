import SwiftUI

struct SettingsView: View {
    @State private var isDarkMode = true
    @State private var selectedLanguage = "English"
    @State private var audioCoachEnabled = true
    
    let languages = ["English", "Vietnamese"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.trueBlack.edgesIgnoringSafeArea(.all)
                
                Form {
                    Section(header: Text("Appearance").foregroundColor(Theme.neonCyan)) {
                        Toggle("Dark Mode", isOn: $isDarkMode)
                            .tint(Theme.neonCyan)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    .foregroundColor(.white)
                    
                    Section(header: Text("Preferences").foregroundColor(Theme.neonCyan)) {
                        Picker("Language", selection: $selectedLanguage) {
                            ForEach(languages, id: \.self) { language in
                                Text(language).tag(language)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Toggle("Audio Coach", isOn: $audioCoachEnabled)
                            .tint(Theme.neonCyan)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                    .foregroundColor(.white)
                    
                    Section(header: Text("Support").foregroundColor(Theme.neonCyan)) {
                        Button("Report / Feedback") {
                            // Action
                        }
                        .foregroundColor(Theme.neonCyan)
                    }
                    .listRowBackground(Color.gray.opacity(0.1))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
