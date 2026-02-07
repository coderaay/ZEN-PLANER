import SwiftUI
import SwiftData

// MARK: - Einstellungen

struct SettingsView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var themeManager = ThemeManager.shared
    @State private var hapticEnabled = HapticManager.isEnabled
    @State private var showQuotes = UserDefaults.standard.object(forKey: "showQuotes") as? Bool ?? true
    @State private var reflectionHour = UserDefaults.standard.object(forKey: "reflectionHour") as? Int ?? 20
    @State private var showDeleteConfirmation = false
    @State private var showDeleteFinalConfirmation = false
    @State private var showExportSheet = false
    @State private var exportText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                List {
                    // Erscheinungsbild
                    Section {
                        Picker("Erscheinungsbild", selection: $themeManager.appearanceMode) {
                            ForEach(AppearanceMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .foregroundStyle(theme.primaryText)
                    } header: {
                        Text("Erscheinungsbild")
                    }

                    // Farbthema
                    Section {
                        ForEach(ColorTheme.allCases) { colorTheme in
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    themeManager.currentTheme = colorTheme
                                }
                                HapticManager.selection()
                            } label: {
                                HStack(spacing: 12) {
                                    // Vorschau-Farben
                                    HStack(spacing: 4) {
                                        ForEach(colorTheme.previewColors.indices, id: \.self) { index in
                                            Circle()
                                                .fill(colorTheme.previewColors[index])
                                                .frame(width: 18, height: 18)
                                        }
                                    }

                                    Text(colorTheme.rawValue)
                                        .foregroundStyle(theme.primaryText)

                                    Spacer()

                                    if themeManager.currentTheme == colorTheme {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(theme.accent)
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("Farbthema")
                    }

                    // Allgemein
                    Section {
                        // Reflexions-Uhrzeit
                        Picker("Reflexion ab", selection: $reflectionHour) {
                            ForEach(17...23, id: \.self) { hour in
                                Text("\(hour):00 Uhr").tag(hour)
                            }
                        }
                        .foregroundStyle(theme.primaryText)
                        .onChange(of: reflectionHour) { _, newValue in
                            UserDefaults.standard.set(newValue, forKey: "reflectionHour")
                        }

                        // Zitate
                        Toggle("Tägliche Zitate", isOn: $showQuotes)
                            .foregroundStyle(theme.primaryText)
                            .tint(theme.accent)
                            .onChange(of: showQuotes) { _, newValue in
                                UserDefaults.standard.set(newValue, forKey: "showQuotes")
                            }

                        // Haptic Feedback
                        Toggle("Haptic Feedback", isOn: $hapticEnabled)
                            .foregroundStyle(theme.primaryText)
                            .tint(theme.accent)
                            .onChange(of: hapticEnabled) { _, newValue in
                                HapticManager.setEnabled(newValue)
                            }
                    } header: {
                        Text("Allgemein")
                    }

                    // Daten
                    Section {
                        Button {
                            exportData()
                        } label: {
                            Label("Daten exportieren", systemImage: "square.and.arrow.up")
                                .foregroundStyle(theme.primaryText)
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Alle Daten löschen", systemImage: "trash")
                                .foregroundStyle(.red)
                        }
                    } header: {
                        Text("Daten")
                    }

                    // Info
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundStyle(theme.primaryText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundStyle(theme.secondaryText)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Zen Planer")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(theme.primaryText)
                            Text("Fokus auf das Wesentliche. Keine Cloud. Nur du und deine 5 Aufgaben.")
                                .font(.caption)
                                .foregroundStyle(theme.secondaryText)
                        }
                    } header: {
                        Text("Über")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Einstellungen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") {
                        dismiss()
                    }
                    .foregroundStyle(theme.accent)
                }
            }
            .alert("Alle Daten löschen?", isPresented: $showDeleteConfirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Fortfahren", role: .destructive) {
                    showDeleteFinalConfirmation = true
                }
            } message: {
                Text("Diese Aktion kann nicht rückgängig gemacht werden.")
            }
            .alert("Wirklich alle Daten löschen?", isPresented: $showDeleteFinalConfirmation) {
                Button("Abbrechen", role: .cancel) {}
                Button("Endgültig löschen", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("Alle Aufgaben und Reflexionen werden unwiderruflich gelöscht.")
            }
            .sheet(isPresented: $showExportSheet) {
                ShareSheet(text: exportText)
            }
        }
    }

    // MARK: - Daten exportieren

    private func exportData() {
        let vm = StatisticsViewModel(modelContext: modelContext)
        exportText = vm.exportAsMarkdown()
        showExportSheet = true
    }

    // MARK: - Alle Daten löschen

    private func deleteAllData() {
        NotificationManager.cancelAll()
        let vm = StatisticsViewModel(modelContext: modelContext)
        vm.deleteAllData()
        HapticManager.medium()
    }
}

// MARK: - Share Sheet (UIKit-Bridge für Datenexport)

struct ShareSheet: UIViewControllerRepresentable {
    let text: String

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .modelContainer(for: [ZenTask.self, DailyReflection.self], inMemory: true)
        .environment(\.colorTheme, .forest)
}
