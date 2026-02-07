import Foundation

// MARK: - Zitat-Datenstruktur

struct Quote: Codable, Identifiable {
    var id: UUID { UUID(uuidString: text) ?? UUID() }
    let text: String
    let author: String

    /// Formatierte Anzeige: "Zitat" - Autor
    var formatted: String {
        "\u{201E}\(text)\u{201C} \u{2013} \(author)"
    }
}

// MARK: - Zitate-Manager

struct QuoteManager {
    /// Alle verfügbaren Zitate aus der JSON-Datei
    static let allQuotes: [Quote] = {
        guard let url = Bundle.main.url(forResource: "quotes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let quotes = try? JSONDecoder().decode([Quote].self, from: data)
        else {
            // Fallback-Zitat, falls die Datei nicht geladen werden kann
            return [Quote(text: "Einfachheit ist die höchste Stufe der Vollendung.", author: "Leonardo da Vinci")]
        }
        return quotes
    }()

    /// Tägliches Zitat – basierend auf dem Datum, damit es den ganzen Tag gleich bleibt
    static func quoteOfTheDay(for date: Date = .now) -> Quote {
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let seed = dayOfYear + year * 366
        let index = seed % allQuotes.count
        return allQuotes[abs(index)]
    }
}
