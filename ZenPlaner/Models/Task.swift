import Foundation
import SwiftData

// MARK: - Erinnerungs-Vorlaufzeit

enum ReminderOffset: String, Codable, CaseIterable {
    case atTime = "atTime"
    case fiveMin = "fiveMin"
    case fifteenMin = "fifteenMin"
    case thirtyMin = "thirtyMin"
    case oneHour = "oneHour"
    case twoHours = "twoHours"

    var displayName: String {
        switch self {
        case .atTime: return "Zum Zeitpunkt"
        case .fiveMin: return "5 Min vorher"
        case .fifteenMin: return "15 Min vorher"
        case .thirtyMin: return "30 Min vorher"
        case .oneHour: return "1 Std vorher"
        case .twoHours: return "2 Std vorher"
        }
    }

    var timeInterval: TimeInterval {
        switch self {
        case .atTime: return 0
        case .fiveMin: return 300
        case .fifteenMin: return 900
        case .thirtyMin: return 1800
        case .oneHour: return 3600
        case .twoHours: return 7200
        }
    }
}

// MARK: - Priorität für Aufgaben

enum Priority: String, Codable, CaseIterable {
    case high
    case medium
    case low

    /// Anzeigename auf Deutsch
    var displayName: String {
        switch self {
        case .high: return "Hoch"
        case .medium: return "Mittel"
        case .low: return "Niedrig"
        }
    }

    /// Sortierreihenfolge (niedrigerer Wert = höhere Priorität)
    var sortValue: Int {
        switch self {
        case .high: return 0
        case .medium: return 1
        case .low: return 2
        }
    }
}

// MARK: - Aufgaben-Datenmodell

@Model
final class ZenTask {
    var id: UUID
    var text: String
    var priority: Priority
    var isCompleted: Bool
    var date: Date
    var sortOrder: Int
    var createdAt: Date
    var completedAt: Date?
    var deadline: Date?
    var reminderOffset: ReminderOffset?
    var isRepeating: Bool

    init(
        text: String,
        priority: Priority = .medium,
        date: Date = .now,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.text = String(text.prefix(100)) // Max 100 Zeichen
        self.priority = priority
        self.isCompleted = false
        self.date = date
        self.sortOrder = sortOrder
        self.isRepeating = false
        self.createdAt = .now
        self.completedAt = nil
    }

    /// Aufgabe als erledigt markieren
    func markCompleted() {
        isCompleted = true
        completedAt = .now
    }

    /// Aufgabe wieder als offen markieren
    func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }
}
