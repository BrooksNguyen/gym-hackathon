import SwiftUI

struct Theme {
    @Environment(\.colorScheme) static var colorScheme
    
    // Semantic Background Colors
    static let background = Color("Background") // Define in Assets, fallback below
    static let secondaryBackground = Color("SecondaryBackground")
    
    static func backgroundColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.black : Color(red: 0.98, green: 0.96, blue: 0.93) // Off-white/Beige
    }
    
    static func cardColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    // Primary Accents
    static func primaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.red : Color(red: 0.76, green: 0.44, blue: 0.35) // Crimson vs Terracotta
    }
    
    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.cyan : Color(red: 0.53, green: 0.63, blue: 0.52) // Cyan vs Sage Green
    }
    
    // Typography using SF Pro
    static let largeTitle = Font.system(size: 34, weight: .bold, design: .default)
    static let title = Font.system(size: 28, weight: .semibold, design: .default)
    static let headline = Font.system(size: 20, weight: .semibold, design: .default)
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    static let caption = Font.system(size: 14, weight: .medium, design: .default)
    
    // Kept for backward compatibility in smaller areas, but we transition to SF Pro
    static let digitalFont = Font.system(.body, design: .monospaced)
    static let titleFont = Font.system(.title, design: .monospaced).bold()
}
