import SwiftUI

struct Theme {
    @Environment(\.colorScheme) static var colorScheme
    
    // Semantic Background Colors
    static func backgroundColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.black : Color(red: 0.96, green: 0.95, blue: 0.92)
    }
    
    // We will use Material for Cards now, so this is just a fallback/tint if needed
    static func cardTintColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05)
    }
    
    // Primary Accents (Cyber Crimson / Terracotta)
    static func primaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color(red: 1.0, green: 0.2, blue: 0.3) : Color(red: 0.8, green: 0.3, blue: 0.2)
    }
    
    // Secondary Accents (Cyber Cyan / Sage Green)
    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.cyan : Color(red: 0.4, green: 0.6, blue: 0.5)
    }
    
    // Typography - Extreme Hierarchy
    static let heroText = Font.system(size: 34, weight: .heavy, design: .default) // Huge headers
    static let primaryText = Font.system(size: 22, weight: .bold, design: .default) // Section titles
    static let secondaryText = Font.system(size: 16, weight: .medium, design: .default) // Body text
    static let tertiaryText = Font.system(size: 13, weight: .semibold, design: .default).uppercaseSmallCaps() // Small labels
    
    // Numbers - Athletic Stopwatch style
    static func numberFont(size: CGFloat) -> Font {
        return Font.system(size: size, weight: .heavy, design: .rounded)
    }
    
    // Background View for the true Cyber-Athletic feel
    struct AppBackground: View {
        var scheme: ColorScheme
        var body: some View {
            ZStack {
                Theme.backgroundColor(for: scheme).edgesIgnoringSafeArea(.all)
                
                // Add some subtle ambient glows
                Circle()
                    .fill(Theme.primaryAccent(for: scheme).opacity(0.15))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Theme.secondaryAccent(for: scheme).opacity(0.1))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .offset(x: 200, y: 300)
            }
        }
    }
}

// Custom Glassmorphism Modifier
struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassmorphismModifier(cornerRadius: cornerRadius))
    }
}
