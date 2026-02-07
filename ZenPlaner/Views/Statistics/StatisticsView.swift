import SwiftUI
import SwiftData

// MARK: - Statistik-Hauptansicht

struct StatisticsView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var viewModel: StatisticsViewModel?
    @State private var selectedTab = 0
    @State private var selectedMonth: Date = .now

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                if let vm = viewModel {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 28) {
                            // Streak-Anzeige
                            streakSection(vm: vm)

                            // Tab-Auswahl: Woche / Monat
                            Picker("Zeitraum", selection: $selectedTab) {
                                Text("Woche").tag(0)
                                Text("Monat").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)

                            if selectedTab == 0 {
                                weekSection(vm: vm)
                            } else {
                                monthSection(vm: vm)
                            }

                            // Stimmungsverlauf
                            moodSection(vm: vm)

                            Spacer(minLength: 40)
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Rückblick")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundStyle(theme.accent)
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = StatisticsViewModel(modelContext: modelContext)
                }
            }
        }
    }

    // MARK: - Streak

    private func streakSection(vm: StatisticsViewModel) -> some View {
        HStack(spacing: 16) {
            Image(systemName: "flame.fill")
                .font(.title2)
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 2) {
                Text("Du planst seit \(vm.currentStreak) Tagen in Folge bewusst")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.primaryText)

                Text("Bleib dran!")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cardBackground)
        )
        .padding(.horizontal)
    }

    // MARK: - Wochenansicht

    private func weekSection(vm: StatisticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diese Woche")
                .font(.headline)
                .foregroundStyle(theme.primaryText)
                .padding(.horizontal)

            VStack(spacing: 8) {
                ForEach(vm.weekStatistics()) { stat in
                    HStack(spacing: 12) {
                        // Wochentag
                        Text(stat.date.weekdayShort)
                            .font(.caption)
                            .foregroundStyle(
                                stat.date.isToday ? theme.accent : theme.secondaryText
                            )
                            .frame(width: 24)

                        // Fortschrittsbalken
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.secondaryText.opacity(0.1))
                                    .frame(height: 20)

                                if stat.totalCount > 0 {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(theme.accent.opacity(stat.date.isToday ? 1.0 : 0.6))
                                        .frame(
                                            width: max(0, geo.size.width * stat.completionRate),
                                            height: 20
                                        )
                                }
                            }
                        }
                        .frame(height: 20)

                        // Zahlen
                        Text("\(stat.completedCount)/\(stat.totalCount)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(theme.secondaryText)
                            .frame(width: 32)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Monatsansicht (Heatmap)

    private func monthSection(vm: StatisticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Monats-Navigation
            HStack {
                Button {
                    withAnimation {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Text(selectedMonth.formattedMonthYear)
                    .font(.headline)
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Button {
                    withAnimation {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(theme.secondaryText)
                }
            }
            .padding(.horizontal)

            HeatmapView(
                statistics: vm.monthStatistics(for: selectedMonth),
                date: selectedMonth
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Stimmungsverlauf

    private func moodSection(vm: StatisticsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stimmungsverlauf")
                .font(.headline)
                .foregroundStyle(theme.primaryText)
                .padding(.horizontal)

            let moodData = vm.moodHistory(days: 14)

            if moodData.isEmpty {
                Text("Noch keine Reflexionen vorhanden.")
                    .font(.subheadline)
                    .foregroundStyle(theme.secondaryText)
                    .padding(.horizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(moodData, id: \.date) { item in
                            VStack(spacing: 6) {
                                Text(item.mood.emoji)
                                    .font(.title2)

                                Text(item.date.formattedDayShort)
                                    .font(.caption2)
                                    .foregroundStyle(theme.secondaryText)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [ZenTask.self, DailyReflection.self], inMemory: true)
        .environment(\.colorTheme, .forest)
}
