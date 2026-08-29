import SwiftUI

struct Theme {
    @Environment(\.colorScheme) static var colorScheme
    
    // Semantic Background Colors
    static func backgroundColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.black : Color(red: 0.98, green: 0.96, blue: 0.93)
    }
    
    static func cardColor(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color(white: 0.1) : Color.white
    }
    
    // Primary Accents (Only for Interactive / Energy / Highlights)
    static func primaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.red : Color(red: 0.76, green: 0.44, blue: 0.35)
    }
    
    static func secondaryAccent(for scheme: ColorScheme) -> Color {
        return scheme == .dark ? Color.cyan : Color(red: 0.53, green: 0.63, blue: 0.52)
    }
    
    // Typography - STRICT 3-TIER HIERARCHY
    static let primaryText = Font.title2.bold() // Primary Text (Titles, Main Values)
    static let secondaryText = Font.callout // Secondary Text (Subtitles, Standard Body)
    static let tertiaryText = Font.caption // Tertiary Text (Small labels, hints)
    
    // Specifically for large numbers
    static func numberFont(size: CGFloat) -> Font {
        return Font.system(size: size, weight: .bold, design: .rounded)
    }
}
