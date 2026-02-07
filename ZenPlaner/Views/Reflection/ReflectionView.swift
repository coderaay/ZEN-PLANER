import SwiftUI
import SwiftData

// MARK: - Abend-Reflexion

struct ReflectionView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var taskViewModel: TaskViewModel
    var reflectionViewModel: ReflectionViewModel

    @State private var wentWell: String = ""
    @State private var shiftConsciously: String = ""
    @State private var selectedMood: Mood = .neutral
    @State private var showCompletion = false

    private var completedCount: Int {
        taskViewModel.completedCount(for: .now)
    }

    private var totalCount: Int {
        taskViewModel.totalCount(for: .now)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                if showCompletion {
                    completionView
                } else {
                    reflectionForm
                }
            }
            .navigationTitle("Abend-Reflexion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !showCompletion {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Schließen") {
                            dismiss()
                        }
                        .foregroundStyle(theme.secondaryText)
                    }
                }
            }
        }
    }

    // MARK: - Reflexions-Formular

    private var reflectionForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                // Zusammenfassung
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dein Tag")
                        .font(.headline)
                        .foregroundStyle(theme.primaryText)

                    Text("Du hast heute \(completedCount) von \(totalCount) Aufgaben geschafft.")
                        .font(.body)
                        .foregroundStyle(theme.secondaryText)

                    // Fortschrittsbalken
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.secondaryText.opacity(0.15))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.accent)
                                .frame(
                                    width: totalCount > 0
                                        ? geo.size.width * CGFloat(completedCount) / CGFloat(totalCount)
                                        : 0,
                                    height: 8
                                )
                        }
                    }
                    .frame(height: 8)
                }

                // Was lief heute gut?
                VStack(alignment: .leading, spacing: 8) {
                    Text("Was lief heute gut?")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)

                    TextField("Optional – max. 200 Zeichen", text: $wentWell, axis: .vertical)
                        .font(.body)
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(3...5)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.cardBackground)
                        )
                        .onChange(of: wentWell) { _, newValue in
                            if newValue.count > 200 {
                                wentWell = String(newValue.prefix(200))
                            }
                        }
                }

                // Was verschiebe ich bewusst?
                VStack(alignment: .leading, spacing: 8) {
                    Text("Was verschiebe ich bewusst?")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)

                    TextField("Optional – max. 200 Zeichen", text: $shiftConsciously, axis: .vertical)
                        .font(.body)
                        .foregroundStyle(theme.primaryText)
                        .lineLimit(3...5)
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(theme.cardBackground)
                        )
                        .onChange(of: shiftConsciously) { _, newValue in
                            if newValue.count > 200 {
                                shiftConsciously = String(newValue.prefix(200))
                            }
                        }
                }

                // Stimmung
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wie fühlst du dich?")
                        .font(.subheadline)
                        .foregroundStyle(theme.secondaryText)

                    MoodPicker(selectedMood: $selectedMood)
                }

                // Tag abschließen
                Button {
                    saveReflection()
                } label: {
                    Text("Tag abschließen")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.accent)
                        )
                }
                .padding(.top, 8)
                .accessibilityLabel("Tagesreflexion abschließen und speichern")
            }
            .padding(24)
        }
    }

    // MARK: - Abschluss-Ansicht

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(theme.accent)

            Text("Gute Nacht")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(theme.primaryText)

            Text("Dein Tag ist abgeschlossen.\nMorgen ist ein neuer Anfang.")
                .font(.body)
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)

            Spacer()

            Button {
                dismiss()
            } label: {
                Text("Schließen")
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
        .transition(.opacity)
    }

    // MARK: - Speichern

    private func saveReflection() {
        reflectionViewModel.saveReflection(
            completedCount: completedCount,
            totalCount: totalCount,
            wentWell: wentWell.isEmpty ? nil : wentWell,
            shiftConsciously: shiftConsciously.isEmpty ? nil : shiftConsciously,
            mood: selectedMood
        )

        withAnimation(.easeInOut(duration: 0.5)) {
            showCompletion = true
        }
    }
}

#Preview {
    @Previewable @State var preview = true
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: ZenTask.self, DailyReflection.self, configurations: config)

    ReflectionView(
        taskViewModel: TaskViewModel(modelContext: container.mainContext),
        reflectionViewModel: ReflectionViewModel(modelContext: container.mainContext)
    )
    .environment(\.colorTheme, .forest)
    .modelContainer(container)
}
