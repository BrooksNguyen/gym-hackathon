import SwiftUI

struct MainTabView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            AICoachView()
                .tabItem {
                    Label("AI Coach", systemImage: "message.and.waveform.fill")
                }
                .tag(1)
            
            MeView()
                .tabItem {
                    Label("Me", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .animation(.easeInOut(duration: 0.3), value: selectedTab)
        .tint(Theme.primaryAccent(for: colorScheme))
    }
}
