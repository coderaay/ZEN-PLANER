import Foundation

// MARK: - Datums-Hilfsfunktionen

struct DateHelper {
    private static let calendar = Calendar.current

    /// Prüft, ob zwei Daten am selben Tag liegen
    static func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        calendar.isDate(date1, inSameDayAs: date2)
    }

    /// Prüft, ob ein Datum heute ist
    static func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }

    /// Gibt den Beginn des Tages zurück (00:00:00)
    static func startOfDay(_ date: Date = .now) -> Date {
        calendar.startOfDay(for: date)
    }

    /// Gibt das Ende des Tages zurück (23:59:59)
    static func endOfDay(_ date: Date = .now) -> Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return calendar.date(byAdding: components, to: startOfDay(date)) ?? date
    }

    /// Gibt das Datum von morgen zurück
    static func tomorrow(from date: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: 1, to: startOfDay(date)) ?? date
    }

    /// Gibt das Datum von vor X Tagen zurück
    static func daysAgo(_ days: Int, from date: Date = .now) -> Date {
        calendar.date(byAdding: .day, value: -days, to: startOfDay(date)) ?? date
    }

    /// Prüft, ob es nach einer bestimmten Uhrzeit ist (für Abend-Reflexion)
    static func isAfterTime(hour: Int, minute: Int = 0, date: Date = .now) -> Bool {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        let currentMinutes = (components.hour ?? 0) * 60 + (components.minute ?? 0)
        let targetMinutes = hour * 60 + minute
        return currentMinutes >= targetMinutes
    }

    /// Gibt alle Tage einer Woche zurück (Montag bis Sonntag)
    static func daysOfWeek(containing date: Date = .now) -> [Date] {
        var cal = Calendar.current
        cal.firstWeekday = 2 // Montag
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: date) else {
            return []
        }
        return (0..<7).compactMap { day in
            cal.date(byAdding: .day, value: day, to: weekInterval.start)
        }
    }

    /// Gibt alle Tage eines Monats zurück
    static func daysOfMonth(containing date: Date = .now) -> [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: date),
              let firstOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date))
        else {
            return []
        }
        return range.compactMap { day in
            calendar.date(byAdding: .day, value: day - 1, to: firstOfMonth)
        }
    }

    /// Wochentag-Index (1 = Montag, 7 = Sonntag)
    static func weekdayIndex(of date: Date) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        // Calendar.current hat Sonntag = 1, Montag = 2, ...
        // Wir wollen Montag = 1, Sonntag = 7
        return weekday == 1 ? 7 : weekday - 1
    }
}
