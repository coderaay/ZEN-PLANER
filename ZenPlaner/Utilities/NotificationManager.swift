import UserNotifications

// MARK: - Benachrichtigungs-Verwaltung

struct NotificationManager {

    /// Berechtigung für Benachrichtigungen anfragen
    static func requestPermission() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Erinnerung für eine Aufgabe planen
    static func scheduleReminder(for task: ZenTask) {
        guard let deadline = task.deadline,
              let offset = task.reminderOffset else { return }

        let fireDate = deadline.addingTimeInterval(-offset.timeInterval)

        // Nicht planen wenn in der Vergangenheit
        guard fireDate > Date.now else { return }

        let content = UNMutableNotificationContent()
        content.title = "Zen Planer"
        content.body = task.text
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: task.id.uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    /// Erinnerung für eine Aufgabe entfernen
    static func cancelReminder(for task: ZenTask) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [task.id.uuidString])
    }

    /// Alle Erinnerungen entfernen
    static func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
