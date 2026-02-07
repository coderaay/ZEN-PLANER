import Foundation
import SwiftData
import SwiftUI

// MARK: - Reflexion-ViewModel

@Observable
final class ReflectionViewModel {
    private var modelContext: ModelContext

    /// Uhrzeit für den Reflexions-Vorschlag (Standard: 20:00)
    var reflectionHour: Int {
        get { UserDefaults.standard.object(forKey: "reflectionHour") as? Int ?? 20 }
        set { UserDefaults.standard.set(newValue, forKey: "reflectionHour") }
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Abfragen

    /// Reflexion für ein bestimmtes Datum laden
    func reflection(for date: Date) -> DailyReflection? {
        let startOfDay = DateHelper.startOfDay(date)
        let endOfDay = DateHelper.endOfDay(date)

        let predicate = #Predicate<DailyReflection> { reflection in
            reflection.date >= startOfDay && reflection.date <= endOfDay
        }

        let descriptor = FetchDescriptor<DailyReflection>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }

    /// Prüft, ob die heutige Reflexion bereits abgeschlossen ist
    var isTodayReflectionComplete: Bool {
        reflection(for: .now) != nil
    }

    /// Prüft, ob der Reflexions-Banner angezeigt werden soll
    var shouldShowReflectionBanner: Bool {
        guard !isTodayReflectionComplete else { return false }
        return DateHelper.isAfterTime(hour: reflectionHour)
    }

    /// Alle Reflexionen der letzten X Tage
    func reflections(lastDays days: Int) -> [DailyReflection] {
        let startDate = DateHelper.daysAgo(days)

        let predicate = #Predicate<DailyReflection> { reflection in
            reflection.date >= startDate
        }

        let descriptor = FetchDescriptor<DailyReflection>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Aktuelle Streak (aufeinanderfolgende Tage mit Reflexion)
    var currentStreak: Int {
        var streak = 0
        var checkDate = Date.now

        // Wenn heute noch keine Reflexion vorhanden, starte ab gestern
        if reflection(for: checkDate) == nil {
            checkDate = DateHelper.daysAgo(1)
        }

        while reflection(for: checkDate) != nil {
            streak += 1
            checkDate = DateHelper.daysAgo(1, from: checkDate)
        }

        return streak
    }

    // MARK: - Aktionen

    /// Tagesreflexion speichern
    @discardableResult
    func saveReflection(
        date: Date = .now,
        completedCount: Int,
        totalCount: Int,
        wentWell: String?,
        shiftConsciously: String?,
        mood: Mood
    ) -> DailyReflection {
        // Bestehende Reflexion für den Tag löschen (falls vorhanden)
        if let existing = reflection(for: date) {
            modelContext.delete(existing)
        }

        let reflection = DailyReflection(
            date: DateHelper.startOfDay(date),
            completedCount: completedCount,
            totalCount: totalCount,
            wentWell: wentWell,
            shiftConsciously: shiftConsciously,
            mood: mood
        )

        modelContext.insert(reflection)
        save()
        Task { @MainActor in HapticManager.success() }
        return reflection
    }

    // MARK: - Persistenz

    private func save() {
        try? modelContext.save()
    }
}
