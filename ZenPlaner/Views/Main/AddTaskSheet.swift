import SwiftUI

// MARK: - Aufgabe hinzufügen / bearbeiten

struct AddTaskSheet: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    @State var taskText: String = ""
    @State var priority: Priority = .medium
    @State private var showDeadline: Bool = false
    @State private var deadlineDate: Date = Date()
    @State private var reminderOffset: ReminderOffset? = nil
    @State private var showPermissionAlert: Bool = false
    @State private var isRepeating: Bool = false

    /// Optionaler bestehender Task zum Bearbeiten
    var editingTask: ZenTask?

    /// Callback wenn gespeichert wird
    let onSave: (String, Priority, Date?, ReminderOffset?, Bool) -> Void

    private var isEditing: Bool { editingTask != nil }
    private var isValid: Bool { !taskText.trimmingCharacters(in: .whitespaces).isEmpty }

    private var deadlineFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "de_DE")
        return f
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        // Textfeld
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Aufgabe")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)

                            TextField("Was ist heute wichtig?", text: $taskText)
                                .font(.body)
                                .foregroundStyle(theme.primaryText)
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(theme.cardBackground)
                                )
                                .onChange(of: taskText) { _, newValue in
                                    if newValue.count > 100 {
                                        taskText = String(newValue.prefix(100))
                                    }
                                }

                            Text("\(taskText.count)/100")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }

                        // Prioritätsauswahl
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Priorität")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)

                            HStack(spacing: 12) {
                                ForEach(Priority.allCases, id: \.self) { prio in
                                    Button {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            priority = prio
                                        }
                                        HapticManager.selection()
                                    } label: {
                                        HStack(spacing: 8) {
                                            PriorityDot(priority: prio, size: 12)
                                            Text(prio.displayName)
                                                .font(.subheadline)
                                        }
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(priority == prio ? theme.color(for: prio).opacity(0.15) : theme.cardBackground)
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .strokeBorder(
                                                    priority == prio ? theme.color(for: prio) : .clear,
                                                    lineWidth: 1.5
                                                )
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .foregroundStyle(theme.primaryText)
                                    .accessibilityLabel("Priorität \(prio.displayName)")
                                    .accessibilityAddTraits(priority == prio ? .isSelected : [])
                                }
                            }
                        }

                        // Frist
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Frist")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showDeadline.toggle()
                                    if !showDeadline {
                                        reminderOffset = nil
                                    }
                                }
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: showDeadline ? "clock.fill" : "clock")
                                        .font(.subheadline)
                                    Text(showDeadline ? deadlineFormatter.string(from: deadlineDate) : "Keine Frist")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(showDeadline ? theme.accent.opacity(0.15) : theme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            showDeadline ? theme.accent : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(theme.primaryText)

                            if showDeadline {
                                DatePicker(
                                    "Frist",
                                    selection: $deadlineDate,
                                    in: Date()...DateHelper.endOfDay(),
                                    displayedComponents: [.hourAndMinute]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .environment(\.locale, Locale(identifier: "de_DE"))
                                .foregroundStyle(theme.primaryText)
                                .tint(theme.accent)
                            }
                        }

                        // Erinnerung (nur sichtbar wenn Deadline gesetzt)
                        if showDeadline {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Erinnerung")
                                    .font(.subheadline)
                                    .foregroundStyle(theme.secondaryText)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        // "Keine" Option
                                        reminderChip(label: "Keine", isSelected: reminderOffset == nil) {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                reminderOffset = nil
                                            }
                                            HapticManager.selection()
                                        }

                                        ForEach(ReminderOffset.allCases, id: \.self) { offset in
                                            reminderChip(label: offset.displayName, isSelected: reminderOffset == offset) {
                                                Task {
                                                    let granted = await NotificationManager.requestPermission()
                                                    if granted {
                                                        withAnimation(.easeInOut(duration: 0.2)) {
                                                            reminderOffset = offset
                                                        }
                                                    } else {
                                                        showPermissionAlert = true
                                                    }
                                                }
                                                HapticManager.selection()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Wiederholung
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Wiederholung")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)

                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    isRepeating.toggle()
                                }
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: isRepeating ? "repeat.circle.fill" : "repeat.circle")
                                        .font(.subheadline)
                                    Text(isRepeating ? "Täglich wiederholen" : "Nicht wiederholen")
                                        .font(.subheadline)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isRepeating ? theme.accent.opacity(0.15) : theme.cardBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .strokeBorder(
                                            isRepeating ? theme.accent : .clear,
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(theme.primaryText)
                        }

                        Spacer()
                    }
                    .padding(24)
                }
            }
            .navigationTitle(isEditing ? "Aufgabe bearbeiten" : "Neue Aufgabe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
                        dismiss()
                    }
                    .foregroundStyle(theme.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let trimmedText = taskText.trimmingCharacters(in: .whitespaces)
                        guard !trimmedText.isEmpty else { return }
                        let deadline = showDeadline ? deadlineDate : nil
                        let reminder = showDeadline ? reminderOffset : nil
                        onSave(trimmedText, priority, deadline, reminder, isRepeating)
                        HapticManager.light()
                        dismiss()
                    }
                    .foregroundStyle(isValid ? theme.accent : theme.secondaryText)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let task = editingTask {
                    taskText = task.text
                    priority = task.priority
                    isRepeating = task.isRepeating
                    if let dl = task.deadline {
                        showDeadline = true
                        deadlineDate = max(dl, Date())
                        reminderOffset = task.reminderOffset
                    }
                }
            }
            .alert("Benachrichtigungen deaktiviert", isPresented: $showPermissionAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Bitte aktiviere Benachrichtigungen in den Einstellungen, um Erinnerungen zu erhalten.")
            }
        }
    }

    // MARK: - Erinnerungs-Chip

    private func reminderChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? theme.accent.opacity(0.15) : theme.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(
                            isSelected ? theme.accent : .clear,
                            lineWidth: 1.5
                        )
                )
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primaryText)
    }
}

#Preview {
    AddTaskSheet { text, priority, _, _, _ in
        print("Saved: \(text), \(priority)")
    }
    .environment(\.colorTheme, .forest)
}
