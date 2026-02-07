import Foundation
import SwiftData
import SwiftUI

// MARK: - Statistik-ViewModel

@Observable
final class StatisticsViewModel {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Datenstrukturen

    /// Tagesdaten für die Statistik-Anzeige
    struct DayStatistic: Identifiable {
        let id = UUID()
        let date: Date
        let completedCount: Int
        let totalCount: Int
        let mood: Mood?

        var completionRate: Double {
            guard totalCount > 0 else { return 0 }
            return Double(completedCount) / Double(totalCount)
        }
    }

    // MARK: - Wochen-Statistik

    /// Statistiken der aktuellen Woche
    func weekStatistics(for date: Date = .now) -> [DayStatistic] {
        let days = DateHelper.daysOfWeek(containing: date)
        return days.map { day in
            let reflection = fetchReflection(for: day)
            let tasks = fetchTasks(for: day)

            return DayStatistic(
                date: day,
                completedCount: reflection?.completedCount ?? tasks.filter(\.isCompleted).count,
                totalCount: reflection?.totalCount ?? tasks.count,
                mood: reflection?.mood
            )
        }
    }

    // MARK: - Monats-Statistik (Heatmap)

    /// Statistiken für den gesamten Monat
    func monthStatistics(for date: Date = .now) -> [DayStatistic] {
        let days = DateHelper.daysOfMonth(containing: date)
        return days.map { day in
            let reflection = fetchReflection(for: day)
            let tasks = fetchTasks(for: day)

            return DayStatistic(
                date: day,
                completedCount: reflection?.completedCount ?? tasks.filter(\.isCompleted).count,
                totalCount: reflection?.totalCount ?? tasks.count,
                mood: reflection?.mood
            )
        }
    }

    // MARK: - Stimmungsverlauf

    /// Stimmungswerte der letzten X Tage
    func moodHistory(days: Int = 30) -> [(date: Date, mood: Mood)] {
        let startDate = DateHelper.daysAgo(days)

        let predicate = #Predicate<DailyReflection> { reflection in
            reflection.date >= startDate
        }

        let descriptor = FetchDescriptor<DailyReflection>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date)]
        )

        let reflections = (try? modelContext.fetch(descriptor)) ?? []
        return reflections.map { (date: $0.date, mood: $0.mood) }
    }

    // MARK: - Streak

    /// Aktuelle Streak (aufeinanderfolgende Tage mit mindestens einer Aufgabe)
    var currentStreak: Int {
        var streak = 0
        var checkDate = Date.now

        // Prüfe, ob heute Aufgaben vorhanden sind
        if fetchTasks(for: checkDate).isEmpty {
            checkDate = DateHelper.daysAgo(1)
        }

        while !fetchTasks(for: checkDate).isEmpty {
            streak += 1
            checkDate = DateHelper.daysAgo(1, from: checkDate)
        }

        return streak
    }

    // MARK: - Daten-Export

    /// Exportiert alle Daten als JSON-String
    func exportAsJSON() -> String {
        let allTasks = fetchAllTasks()
        let allReflections = fetchAllReflections()

        var export: [[String: Any]] = []

        // Tasks exportieren
        let taskEntries: [[String: Any]] = allTasks.map { task in
            [
                "type": "task",
                "text": task.text,
                "priority": task.priority.rawValue,
                "isCompleted": task.isCompleted,
                "date": ISO8601DateFormatter().string(from: task.date),
                "createdAt": ISO8601DateFormatter().string(from: task.createdAt)
            ]
        }

        // Reflexionen exportieren
        let reflectionEntries: [[String: Any]] = allReflections.map { ref in
            var entry: [String: Any] = [
                "type": "reflection",
                "date": ISO8601DateFormatter().string(from: ref.date),
                "completedCount": ref.completedCount,
                "totalCount": ref.totalCount,
                "mood": ref.mood.rawValue
            ]
            if let wentWell = ref.wentWell { entry["wentWell"] = wentWell }
            if let shift = ref.shiftConsciously { entry["shiftConsciously"] = shift }
            return entry
        }

        export.append(contentsOf: taskEntries)
        export.append(contentsOf: reflectionEntries)

        guard let data = try? JSONSerialization.data(withJSONObject: export, options: .prettyPrinted),
              let jsonString = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }

        return jsonString
    }

    /// Exportiert alle Daten als Markdown-String
    func exportAsMarkdown() -> String {
        let allTasks = fetchAllTasks()
        let allReflections = fetchAllReflections()

        var markdown = "# Zen Planer Export\n\n"

        // Nach Datum gruppieren
        let tasksByDate = Dictionary(grouping: allTasks) { task in
            DateHelper.startOfDay(task.date)
        }.sorted { $0.key > $1.key }

        for (date, tasks) in tasksByDate {
            markdown += "## \(date.formattedDayLong)\n\n"

            for task in tasks.sorted(by: { $0.sortOrder < $1.sortOrder }) {
                let check = task.isCompleted ? "[x]" : "[ ]"
                let priority = task.priority.displayName
                markdown += "- \(check) \(task.text) (\(priority))\n"
            }

            if let reflection = allReflections.first(where: { DateHelper.isSameDay($0.date, date) }) {
                markdown += "\n**Stimmung:** \(reflection.mood.emoji) \(reflection.mood.displayName)\n"
                markdown += "**Erledigt:** \(reflection.completedCount)/\(reflection.totalCount)\n"
                if let wentWell = reflection.wentWell, !wentWell.isEmpty {
                    markdown += "**Was lief gut:** \(wentWell)\n"
                }
                if let shift = reflection.shiftConsciously, !shift.isEmpty {
                    markdown += "**Bewusst verschoben:** \(shift)\n"
                }
            }
            markdown += "\n---\n\n"
        }

        return markdown
    }

    // MARK: - Alle Daten löschen

    func deleteAllData() {
        let allTasks = fetchAllTasks()
        let allReflections = fetchAllReflections()

        for task in allTasks {
            modelContext.delete(task)
        }
        for reflection in allReflections {
            modelContext.delete(reflection)
        }
        try? modelContext.save()
    }

    // MARK: - Private Hilfsfunktionen

    private func fetchTasks(for date: Date) -> [ZenTask] {
        let startOfDay = DateHelper.startOfDay(date)
        let endOfDay = DateHelper.endOfDay(date)

        let predicate = #Predicate<ZenTask> { task in
            task.date >= startOfDay && task.date <= endOfDay
        }

        let descriptor = FetchDescriptor<ZenTask>(predicate: predicate)
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchReflection(for date: Date) -> DailyReflection? {
        let startOfDay = DateHelper.startOfDay(date)
        let endOfDay = DateHelper.endOfDay(date)

        let predicate = #Predicate<DailyReflection> { reflection in
            reflection.date >= startOfDay && reflection.date <= endOfDay
        }

        let descriptor = FetchDescriptor<DailyReflection>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }

    private func fetchAllTasks() -> [ZenTask] {
        let descriptor = FetchDescriptor<ZenTask>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    private func fetchAllReflections() -> [DailyReflection] {
        let descriptor = FetchDescriptor<DailyReflection>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }
}
