import Foundation

// MARK: - Datums-Formatierung

extension Date {
    /// Formatiert als „Samstag, 7. Februar"
    var formattedDayLong: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EEEE, d. MMMM"
        return formatter.string(from: self)
    }

    /// Formatiert als „7. Feb"
    var formattedDayShort: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "d. MMM"
        return formatter.string(from: self)
    }

    /// Formatiert als „Februar 2025"
    var formattedMonthYear: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Kurzform des Wochentags: „Mo", „Di", etc.
    var weekdayShort: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "de_DE")
        formatter.dateFormat = "EE"
        return formatter.string(from: self)
    }

    /// Tag des Monats als Zahl
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Prüft, ob dieses Datum heute ist
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
}
