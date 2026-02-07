import SwiftUI
import SwiftData

// MARK: - Archiv-Ansicht

struct ArchiveView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    let taskViewModel: TaskViewModel

    private var daysWithTasks: [(date: Date, tasks: [ZenTask])] {
        (1...30).compactMap { daysAgo in
            let date = DateHelper.daysAgo(daysAgo)
            let tasks = taskViewModel.tasks(for: date)
            guard !tasks.isEmpty else { return nil }
            return (date, tasks)
        }
    }

    private var dateFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "EEEE, d. MMMM"
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                if daysWithTasks.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 24) {
                            ForEach(daysWithTasks, id: \.date) { day in
                                daySection(date: day.date, tasks: day.tasks)
                            }
                        }
                        .padding(24)
                    }
                }
            }
            .navigationTitle("Archiv")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Schließen") {
                        dismiss()
                    }
                    .foregroundStyle(theme.secondaryText)
                }
            }
        }
    }

    // MARK: - Leerer Zustand

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "archivebox")
                .font(.system(size: 40))
                .foregroundStyle(theme.secondaryText.opacity(0.4))

            Text("Noch keine vergangenen Aufgaben")
                .font(.subheadline)
                .foregroundStyle(theme.secondaryText)
        }
    }

    // MARK: - Tages-Sektion

    private func daySection(date: Date, tasks: [ZenTask]) -> some View {
        let completed = tasks.filter(\.isCompleted).count

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(dateFormatter.string(from: date))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.primaryText)

                Spacer()

                Text("\(completed)/\(tasks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(theme.secondaryText)
            }

            ForEach(tasks) { task in
                archiveRow(task: task)
            }
        }
    }

    // MARK: - Read-Only Task-Zeile

    private func archiveRow(task: ZenTask) -> some View {
        HStack(spacing: 14) {
            // Checkbox (read-only)
            ZStack {
                Circle()
                    .strokeBorder(
                        task.isCompleted ? theme.accent : theme.secondaryText.opacity(0.4),
                        lineWidth: 2
                    )
                    .frame(width: 22, height: 22)

                if task.isCompleted {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 22, height: 22)

                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
            }

            PriorityDot(priority: task.priority, size: 8)

            Text(task.text)
                .font(.subheadline)
                .foregroundStyle(task.isCompleted ? theme.secondaryText : theme.primaryText)
                .strikethrough(task.isCompleted, color: theme.secondaryText)
                .opacity(task.isCompleted ? 0.5 : 1.0)
                .lineLimit(1)

            Spacer()

            if task.isRepeating {
                Image(systemName: "repeat")
                    .font(.caption2)
                    .foregroundStyle(theme.secondaryText)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.cardBackground)
        )
    }
}

#Preview {
    ArchiveView(taskViewModel: TaskViewModel(modelContext: try! ModelContext(ModelContainer(for: ZenTask.self))))
        .environment(\.colorTheme, .forest)
}
