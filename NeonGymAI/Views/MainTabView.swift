import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "message.and.waveform.fill")
                }
            
            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.circle.fill")
                }
            SettingsView()
                .tabItem {
                    Label("Setting", systemImage: "gearshape.fill")
                }
        }
        .tint(Theme.primaryAccent(for: colorScheme))
    }
}
