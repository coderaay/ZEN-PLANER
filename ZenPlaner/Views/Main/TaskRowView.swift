import SwiftUI

// MARK: - Einzelne Aufgaben-Zeile

struct TaskRowView: View {
    @Environment(\.colorTheme) private var theme
    let task: ZenTask
    let onToggle: () -> Void
    var onTap: (() -> Void)? = nil

    @State private var isChecked = false

    private var deadlineFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    private var isOverdue: Bool {
        guard let deadline = task.deadline else { return false }
        return deadline < Date.now && !task.isCompleted
    }

    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isChecked.toggle()
                }
                onToggle()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? theme.accent : theme.secondaryText.opacity(0.4),
                            lineWidth: 2
                        )
                        .frame(width: 26, height: 26)

                    if task.isCompleted {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 26, height: 26)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(task.isCompleted ? "Als unerledigt markieren" : "Als erledigt markieren")

            // Tappbarer Bereich: Priorität + Text + Deadline
            Button {
                onTap?()
            } label: {
                HStack(spacing: 14) {
                    // Prioritäts-Punkt
                    PriorityDot(priority: task.priority)

                    // Aufgabentext
                    Text(task.text)
                        .font(.body)
                        .foregroundStyle(task.isCompleted ? theme.secondaryText : theme.primaryText)
                        .strikethrough(task.isCompleted, color: theme.secondaryText)
                        .opacity(task.isCompleted ? 0.5 : 1.0)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    // Repeat-Indikator
                    if task.isRepeating {
                        Image(systemName: "repeat")
                            .font(.caption2)
                            .foregroundStyle(theme.secondaryText)
                    }

                    // Deadline-Indikator
                    if let deadline = task.deadline {
                        HStack(spacing: 4) {
                            Image(systemName: task.reminderOffset != nil ? "bell.fill" : "clock")
                                .font(.caption2)
                            Text(deadlineFormatter.string(from: deadline))
                                .font(.caption)
                        }
                        .foregroundStyle(isOverdue ? theme.priorityHigh : theme.secondaryText)
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.cardBackground)
        )
        .onAppear {
            isChecked = task.isCompleted
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(task.text), Priorität \(task.priority.displayName), \(task.isCompleted ? "erledigt" : "offen")")
    }
}

#Preview {
    VStack(spacing: 12) {
        TaskRowView(
            task: ZenTask(text: "Meditation am Morgen", priority: .high),
            onToggle: {}
        )
        TaskRowView(
            task: {
                let t = ZenTask(text: "E-Mails beantworten", priority: .medium)
                t.markCompleted()
                return t
            }(),
            onToggle: {}
        )
        TaskRowView(
            task: ZenTask(text: "Spaziergang im Park", priority: .low),
            onToggle: {}
        )
    }
    .padding()
    .background(Color(hex: "F5F0EB"))
    .environment(\.colorTheme, .forest)
}
