import Foundation
import SwiftData
import SwiftUI

// MARK: - Aufgaben-ViewModel

@Observable
final class TaskViewModel {
    /// Maximale Anzahl an Aufgaben pro Tag
    static let maxTasksPerDay = 5

    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Abfragen

    /// Alle Aufgaben für einen bestimmten Tag laden
    func tasks(for date: Date) -> [ZenTask] {
        let startOfDay = DateHelper.startOfDay(date)
        let endOfDay = DateHelper.endOfDay(date)

        let predicate = #Predicate<ZenTask> { task in
            task.date >= startOfDay && task.date <= endOfDay
        }

        let descriptor = FetchDescriptor<ZenTask>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.sortOrder)]
        )

        return (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Heutige Aufgaben
    var todaysTasks: [ZenTask] {
        tasks(for: .now)
    }

    /// Kann eine weitere Aufgabe für das gegebene Datum hinzugefügt werden?
    func canAddTask(for date: Date) -> Bool {
        tasks(for: date).count < Self.maxTasksPerDay
    }

    /// Anzahl erledigter Aufgaben für ein Datum
    func completedCount(for date: Date) -> Int {
        tasks(for: date).filter(\.isCompleted).count
    }

    /// Gesamtanzahl Aufgaben für ein Datum
    func totalCount(for date: Date) -> Int {
        tasks(for: date).count
    }

    /// Nächste offene Aufgabe (höchste Priorität zuerst)
    func nextOpenTask(for date: Date) -> ZenTask? {
        tasks(for: date)
            .filter { !$0.isCompleted }
            .sorted { $0.priority.sortValue < $1.priority.sortValue }
            .first
    }

    // MARK: - Aktionen

    /// Neue Aufgabe hinzufügen
    @discardableResult
    func addTask(text: String, priority: Priority, date: Date = .now, deadline: Date? = nil, reminderOffset: ReminderOffset? = nil, isRepeating: Bool = false) -> ZenTask? {
        guard canAddTask(for: date) else { return nil }

        let currentTasks = tasks(for: date)
        let nextSortOrder = (currentTasks.map(\.sortOrder).max() ?? -1) + 1

        let task = ZenTask(
            text: text,
            priority: priority,
            date: DateHelper.startOfDay(date),
            sortOrder: nextSortOrder
        )
        task.deadline = deadline
        task.reminderOffset = reminderOffset
        task.isRepeating = isRepeating

        modelContext.insert(task)
        save()

        NotificationManager.scheduleReminder(for: task)

        return task
    }

    /// Aufgabe als erledigt/offen markieren
    func toggleCompletion(_ task: ZenTask) {
        if task.isCompleted {
            task.markIncomplete()
            NotificationManager.scheduleReminder(for: task)
        } else {
            task.markCompleted()
            NotificationManager.cancelReminder(for: task)
            Task { @MainActor in HapticManager.success() }
        }
        save()
    }

    /// Aufgabe löschen
    func deleteTask(_ task: ZenTask) {
        NotificationManager.cancelReminder(for: task)
        modelContext.delete(task)
        save()
        Task { @MainActor in HapticManager.medium() }
    }

    /// Aufgabe auf morgen verschieben
    func moveToTomorrow(_ task: ZenTask) {
        let tomorrow = DateHelper.tomorrow()
        let tomorrowTasks = tasks(for: tomorrow)

        guard tomorrowTasks.count < Self.maxTasksPerDay else { return }

        NotificationManager.cancelReminder(for: task)

        let nextSortOrder = (tomorrowTasks.map(\.sortOrder).max() ?? -1) + 1
        task.date = tomorrow
        task.sortOrder = nextSortOrder
        task.isCompleted = false
        task.completedAt = nil
        task.deadline = nil
        task.reminderOffset = nil
        task.isRepeating = false
        save()
    }

    /// Aufgabentext aktualisieren
    func updateTask(_ task: ZenTask, text: String, priority: Priority, deadline: Date? = nil, reminderOffset: ReminderOffset? = nil, isRepeating: Bool = false) {
        task.text = String(text.prefix(100))
        task.priority = priority
        task.isRepeating = isRepeating

        let deadlineChanged = task.deadline != deadline || task.reminderOffset != reminderOffset
        task.deadline = deadline
        task.reminderOffset = reminderOffset

        if deadlineChanged {
            NotificationManager.cancelReminder(for: task)
            NotificationManager.scheduleReminder(for: task)
        }

        save()
    }

    /// Reihenfolge der Aufgaben aktualisieren (nach Drag & Drop)
    func reorderTasks(_ tasks: [ZenTask]) {
        for (index, task) in tasks.enumerated() {
            task.sortOrder = index
        }
        save()
    }

    /// Wiederholende Tasks von gestern für heute erstellen
    func createRepeatingTasks() {
        let yesterday = DateHelper.daysAgo(1)
        let yesterdayTasks = tasks(for: yesterday).filter { $0.isRepeating }
        let todayTexts = Set(todaysTasks.map(\.text))

        for task in yesterdayTasks {
            guard !todayTexts.contains(task.text) else { continue }
            guard canAddTask(for: .now) else { break }
            let newTask = addTask(
                text: task.text,
                priority: task.priority,
                isRepeating: true
            )
            _ = newTask
        }
    }

    // MARK: - Persistenz

    private func save() {
        try? modelContext.save()
    }
}
