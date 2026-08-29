import SwiftUI

struct Theme {
    @Environment(\.colorScheme) static var colorScheme
    
    // Semantic Background Colors - Metallic/Titanium Theme
    static func backgroundColor(for scheme: ColorScheme) -> Color {
        // Dark Mode: Deep Graphite Black
        // Light Mode: Very Light Brushed Platinum (Off-White with a cool tint)
        return scheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.07) : Color(red: 0.94, green: 0.95, blue: 0.96)
    }
    
    // Primary Accents (Titanium / Liquid Metal)
    static func primaryAccent(for scheme: ColorScheme) -> Color {
        // A sleek, glowing metallic silver/chrome
        return scheme == .dark ? Color(red: 0.8, green: 0.82, blue: 0.85) : Color(red: 0.3, green: 0.32, blue: 0.35)
    }
    
    // Secondary Accents (Electric Cobalt / Cool Steel)
    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        // Adds that "cool/ngầu" vibe without being neon red
        return scheme == .dark ? Color(red: 0.3, green: 0.6, blue: 0.9) : Color(red: 0.2, green: 0.4, blue: 0.7)
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
    
    // Background View for the true Metallic-Athletic feel
    struct AppBackground: View {
        var scheme: ColorScheme
        var body: some View {
            ZStack {
                Theme.backgroundColor(for: scheme).edgesIgnoringSafeArea(.all)
                
                // Add some subtle ambient glows - Cool Steel and Titanium
                Circle()
                    .fill(Theme.primaryAccent(for: scheme).opacity(0.1))
                    .blur(radius: 100)
                    .frame(width: 300, height: 300)
                    .offset(x: -150, y: -200)
                
                Circle()
                    .fill(Theme.secondaryAccent(for: scheme).opacity(0.15))
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
                    .stroke(Color.white.opacity(0.15), lineWidth: 1) // Slightly more visible stroke for metallic edge
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(GlassmorphismModifier(cornerRadius: cornerRadius))
    }
}
