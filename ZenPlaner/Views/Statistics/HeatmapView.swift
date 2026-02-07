import SwiftUI

// MARK: - Kalender-Heatmap

struct HeatmapView: View {
    @Environment(\.colorTheme) private var theme
    let statistics: [StatisticsViewModel.DayStatistic]
    let date: Date

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"]

    /// Offset-Tage am Monatsanfang (leere Felder vor dem 1.)
    private var leadingEmptyDays: Int {
        guard let firstDay = statistics.first?.date else { return 0 }
        return DateHelper.weekdayIndex(of: firstDay) - 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Monats-Titel
            Text(date.formattedMonthYear)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.primaryText)

            // Wochentag-Header
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(theme.secondaryText)
                        .frame(maxWidth: .infinity)
                }
            }

            // Tage mit Heatmap-Farbe
            LazyVGrid(columns: columns, spacing: 4) {
                // Leere Felder am Anfang
                ForEach(0..<leadingEmptyDays, id: \.self) { _ in
                    Color.clear
                        .frame(height: 28)
                }

                // Tage des Monats
                ForEach(statistics) { stat in
                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(heatmapColor(for: stat))
                            .frame(height: 28)

                        if stat.date.isToday {
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(theme.accent, lineWidth: 1.5)
                                .frame(height: 28)
                        }

                        Text("\(stat.date.dayOfMonth)")
                            .font(.caption2)
                            .foregroundStyle(
                                stat.totalCount > 0 ? theme.primaryText : theme.secondaryText.opacity(0.5)
                            )
                    }
                    .accessibilityLabel(accessibilityText(for: stat))
                }
            }

            // Legende
            HStack(spacing: 8) {
                Text("Wenig")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)

                ForEach([0.0, 0.25, 0.5, 0.75, 1.0], id: \.self) { rate in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent.opacity(0.1 + rate * 0.6))
                        .frame(width: 14, height: 14)
                }

                Text("Viel")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)

                Spacer()
            }
            .padding(.top, 4)
        }
    }

    /// Heatmap-Farbe basierend auf der Erledigungsquote
    private func heatmapColor(for stat: StatisticsViewModel.DayStatistic) -> Color {
        guard stat.totalCount > 0 else {
            return theme.secondaryText.opacity(0.05)
        }
        return theme.accent.opacity(0.1 + stat.completionRate * 0.6)
    }

    /// Barrierefreier Text für einen Tag
    private func accessibilityText(for stat: StatisticsViewModel.DayStatistic) -> String {
        let dateText = stat.date.formattedDayShort
        if stat.totalCount == 0 {
            return "\(dateText): Keine Aufgaben"
        }
        return "\(dateText): \(stat.completedCount) von \(stat.totalCount) erledigt"
    }
}

#Preview {
    let stats = (1...28).map { day in
        StatisticsViewModel.DayStatistic(
            date: Calendar.current.date(byAdding: .day, value: day - 1, to: DateHelper.startOfDay())!,
            completedCount: Int.random(in: 0...5),
            totalCount: Int.random(in: 3...5),
            mood: Mood.allCases.randomElement()
        )
    }

    return HeatmapView(statistics: stats, date: .now)
        .padding()
        .environment(\.colorTheme, .forest)
}
