import SwiftUI

// MARK: - Farbthemen

enum ColorTheme: String, CaseIterable, Identifiable {
    case forest = "Wald"
    case ocean = "Ozean"
    case sand = "Sand"

    var id: String { rawValue }

    /// Hintergrundfarbe
    var background: Color {
        switch self {
        case .forest: return Color(hex: "F5F0EB")
        case .ocean: return Color(hex: "EFF5F8")
        case .sand: return Color(hex: "F7F3ED")
        }
    }

    /// Primäre Textfarbe
    var primaryText: Color {
        switch self {
        case .forest: return Color(hex: "2C3E2D")
        case .ocean: return Color(hex: "1B3A4B")
        case .sand: return Color(hex: "3D2E1E")
        }
    }

    /// Sekundäre Textfarbe
    var secondaryText: Color {
        switch self {
        case .forest: return Color(hex: "8A9A8B")
        case .ocean: return Color(hex: "7A9AAD")
        case .sand: return Color(hex: "A89880")
        }
    }

    /// Akzentfarbe
    var accent: Color {
        switch self {
        case .forest: return Color(hex: "6B8F71")
        case .ocean: return Color(hex: "4A90A4")
        case .sand: return Color(hex: "C4956A")
        }
    }

    /// Priorität Hoch
    var priorityHigh: Color {
        switch self {
        case .forest: return Color(hex: "C97B6B")
        case .ocean: return Color(hex: "C97070")
        case .sand: return Color(hex: "C97B6B")
        }
    }

    /// Priorität Mittel
    var priorityMedium: Color {
        switch self {
        case .forest: return Color(hex: "D4A96A")
        case .ocean: return Color(hex: "D4A96A")
        case .sand: return Color(hex: "D4A96A")
        }
    }

    /// Priorität Niedrig
    var priorityLow: Color {
        switch self {
        case .forest: return Color(hex: "7BA386")
        case .ocean: return Color(hex: "6BA3A0")
        case .sand: return Color(hex: "9AB38A")
        }
    }

    /// Farbe für einen Prioritäts-Wert
    func color(for priority: Priority) -> Color {
        switch priority {
        case .high: return priorityHigh
        case .medium: return priorityMedium
        case .low: return priorityLow
        }
    }

    /// Kartenfarbe (leicht vom Hintergrund abgesetzt)
    var cardBackground: Color {
        .white.opacity(0.7)
    }

    /// Vorschaufarbe für die Einstellungen
    var previewColors: [Color] {
        [background, accent, primaryText, priorityHigh]
    }
}

// MARK: - Erscheinungsbild (Hell/Dunkel/System)

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Hell"
    case dark = "Dunkel"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

// MARK: - Theme-Manager

@Observable
final class ThemeManager: @unchecked Sendable {
    /// Singleton-Instanz
    @MainActor static let shared = ThemeManager()

    /// Aktuelles Farbthema
    var currentTheme: ColorTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "selectedTheme")
        }
    }

    /// Erscheinungsbild (Hell/Dunkel/System)
    var appearanceMode: AppearanceMode {
        didSet {
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode")
        }
    }

    private init() {
        let themeRaw = UserDefaults.standard.string(forKey: "selectedTheme") ?? ColorTheme.forest.rawValue
        self.currentTheme = ColorTheme(rawValue: themeRaw) ?? .forest

        let modeRaw = UserDefaults.standard.string(forKey: "appearanceMode") ?? AppearanceMode.system.rawValue
        self.appearanceMode = AppearanceMode(rawValue: modeRaw) ?? .system
    }
}
