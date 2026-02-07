import SwiftUI
import SwiftData

// MARK: - One-Thing-Modus

struct OneThingView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var taskViewModel: TaskViewModel

    @State private var currentTask: ZenTask?
    @State private var showBreathingPhase = true

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            // Atem-Animation im Hintergrund
            if showBreathingPhase {
                BreathingCircle(breathDuration: 4.0)
                    .frame(width: 300, height: 300)
            }

            VStack(spacing: 40) {
                // Schließen-Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(theme.secondaryText)
                            .padding(12)
                    }
                    .accessibilityLabel("One-Thing-Modus schließen")
                }
                .padding(.horizontal)

                Spacer()

                if let task = currentTask {
                    // Aufgabentext
                    VStack(spacing: 20) {
                        if showBreathingPhase {
                            Text("Atme kurz durch...")
                                .font(.subheadline)
                                .foregroundStyle(theme.secondaryText)
                                .transition(.opacity)
                        }

                        Text(task.text)
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(theme.primaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        PriorityDot(priority: task.priority, size: 12)
                    }

                    Spacer()

                    // Erledigt-Button
                    Button {
                        completeCurrentTask()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.headline)
                            Text("Erledigt")
                                .font(.system(.headline, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 48)
                        .background(
                            Capsule()
                                .fill(theme.accent)
                                .shadow(color: theme.accent.opacity(0.3), radius: 8, y: 4)
                        )
                    }
                    .accessibilityLabel("Aufgabe als erledigt markieren")
                    .padding(.bottom, 60)

                } else {
                    // Keine offenen Aufgaben
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle")
                            .font(.system(size: 48))
                            .foregroundStyle(theme.accent)

                        Text("Alles erledigt!")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(theme.primaryText)

                        Text("Du hast alle Aufgaben geschafft.")
                            .font(.body)
                            .foregroundStyle(theme.secondaryText)
                    }

                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Text("Zurück")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(theme.accent)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 48)
                            .background(
                                Capsule()
                                    .strokeBorder(theme.accent, lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .onAppear {
            loadNextTask()
            // Atem-Phase nach 8 Sekunden ausblenden
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                withAnimation(.easeOut(duration: 1.0)) {
                    showBreathingPhase = false
                }
            }
        }
    }

    /// Nächste offene Aufgabe laden
    private func loadNextTask() {
        withAnimation(.easeInOut(duration: 0.4)) {
            currentTask = taskViewModel.nextOpenTask(for: .now)
        }
    }

    /// Aktuelle Aufgabe erledigen und nächste laden
    private func completeCurrentTask() {
        guard let task = currentTask else { return }
        taskViewModel.toggleCompletion(task)
        HapticManager.success()

        withAnimation(.easeInOut(duration: 0.5)) {
            currentTask = nil
        }

        // Nächste Aufgabe nach kurzer Pause laden
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            loadNextTask()
        }
    }
}

#Preview {
    @Previewable @State var preview = true
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ZenTask.self, DailyReflection.self, configurations: config)

    OneThingView(taskViewModel: TaskViewModel(modelContext: container.mainContext))
        .environment(\.colorTheme, .forest)
        .modelContainer(container)
}
