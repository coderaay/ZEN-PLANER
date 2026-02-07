import Foundation
import SwiftData

// MARK: - Stimmung für die Tagesreflexion

enum Mood: String, Codable, CaseIterable {
    case great
    case good
    case neutral
    case bad
    case terrible

    /// Emoji-Darstellung
    var emoji: String {
        switch self {
        case .great: return "😊"
        case .good: return "😌"
        case .neutral: return "😐"
        case .bad: return "😔"
        case .terrible: return "😩"
        }
    }

    /// Anzeigename auf Deutsch
    var displayName: String {
        switch self {
        case .great: return "Großartig"
        case .good: return "Gut"
        case .neutral: return "Neutral"
        case .bad: return "Schlecht"
        case .terrible: return "Furchtbar"
        }
    }

    /// Numerischer Wert für Statistiken (5 = beste Stimmung)
    var numericValue: Int {
        switch self {
        case .great: return 5
        case .good: return 4
        case .neutral: return 3
        case .bad: return 2
        case .terrible: return 1
        }
    }
}

// MARK: - Tagesreflexion-Datenmodell

@Model
final class DailyReflection {
    var id: UUID
    var date: Date
    var completedCount: Int
    var totalCount: Int
    var wentWell: String?
    var shiftConsciously: String?
    var mood: Mood
    var createdAt: Date

    init(
        date: Date,
        completedCount: Int,
        totalCount: Int,
        wentWell: String? = nil,
        shiftConsciously: String? = nil,
        mood: Mood = .neutral
    ) {
        self.id = UUID()
        self.date = date
        self.completedCount = completedCount
        self.totalCount = totalCount
        self.wentWell = wentWell.map { String($0.prefix(200)) } // Max 200 Zeichen
        self.shiftConsciously = shiftConsciously.map { String($0.prefix(200)) }
        self.mood = mood
        self.createdAt = .now
    }

    /// Erledigungsquote als Prozentwert
    var completionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
}
