import SwiftUI

struct Theme {
    @Environment(\.colorScheme) static var colorScheme
    
    // Semantic Background Colors - iPhone Pro Titanium Vibe
    static func backgroundColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color(red: 0.1, green: 0.11, blue: 0.12) : Color(red: 0.88, green: 0.89, blue: 0.91)
    }
    
    static func primaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color(red: 0.8, green: 0.82, blue: 0.85) : Color(red: 0.35, green: 0.38, blue: 0.42)
    }
    
    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color(red: 0.4, green: 0.7, blue: 0.9) : Color(red: 0.2, green: 0.4, blue: 0.7)
    }
    
    // Typography
    static let heroText = Font.system(size: 34, weight: .heavy, design: .default)
    static let primaryText = Font.system(size: 22, weight: .bold, design: .default)
    static let secondaryText = Font.system(size: 16, weight: .semibold, design: .default) // Increased weight to fix readability
    static let tertiaryText = Font.system(size: 13, weight: .bold, design: .default).uppercaseSmallCaps()
    
    static func numberFont(size: CGFloat) -> Font {
        return Font.system(size: size, weight: .heavy, design: .rounded)
    }
    
    // Metallic Background View with Textures (Gradients)
    struct AppBackground: View {
        var scheme: ColorScheme
        var body: some View {
            ZStack {
                // Base Metallic Gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Theme.backgroundColor(for: scheme),
                        scheme == .dark ? Color(red: 0.05, green: 0.05, blue: 0.06) : Color(red: 0.95, green: 0.96, blue: 0.98),
                        Theme.backgroundColor(for: scheme)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Texture overlays using radial gradients to simulate brushed metal sheen
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(scheme == .dark ? 0.05 : 0.4),
                        Color.clear
                    ]),
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 500
                )
                .edgesIgnoringSafeArea(.all)
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        Theme.secondaryAccent(for: scheme).opacity(scheme == .dark ? 0.15 : 0.1),
                        Color.clear
                    ]),
                    center: .bottomTrailing,
                    startRadius: 10,
                    endRadius: 400
                )
                .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

// Metallic Button Modifier (Square, Textured)
struct MetallicButtonModifier: ViewModifier {
    var scheme: ColorScheme
    var isPrimary: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(Theme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: isPrimary ? (scheme == .dark ? 
                        [Color(red: 0.3, green: 0.32, blue: 0.35), Color(red: 0.15, green: 0.16, blue: 0.18)] : 
                        [Color(red: 0.45, green: 0.48, blue: 0.52), Color(red: 0.25, green: 0.28, blue: 0.32)]) :
                        (scheme == .dark ? 
                        [Color(red: 0.2, green: 0.22, blue: 0.25), Color(red: 0.1, green: 0.11, blue: 0.12)] : 
                        [Color(red: 0.9, green: 0.92, blue: 0.95), Color(red: 0.8, green: 0.82, blue: 0.85)])
                    ),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .foregroundColor(isPrimary ? .white : (scheme == .dark ? .white : .black))
            .cornerRadius(8) // Square look
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.6), Color.black.opacity(0.3)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
    }
}

// Glassmorphism Modifier (Adjusted for better contrast)
struct GlassmorphismModifier: ViewModifier {
    var cornerRadius: CGFloat
    var scheme: ColorScheme
    
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(scheme == .dark ? Color.black.opacity(0.3) : Color.white.opacity(0.4)) // Enhance readability
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.white.opacity(0.5), Color.white.opacity(0.1)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, scheme: ColorScheme) -> some View {
        self.modifier(GlassmorphismModifier(cornerRadius: cornerRadius, scheme: scheme))
    }
    
    func metallicButton(scheme: ColorScheme, isPrimary: Bool = true) -> some View {
        self.modifier(MetallicButtonModifier(scheme: scheme, isPrimary: isPrimary))
    }
}
