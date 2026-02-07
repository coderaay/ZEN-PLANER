import SwiftUI
import SwiftData

// MARK: - Hauptscreen – Tagesansicht

struct DayView: View {
    @Environment(\.colorTheme) private var theme
    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<ZenTask> { _ in true },
        sort: \ZenTask.sortOrder
    ) private var allTasks: [ZenTask]

    @State private var taskViewModel: TaskViewModel?
    @State private var reflectionViewModel: ReflectionViewModel?
    @State private var showAddSheet = false
    @State private var showReflection = false
    @State private var showOneThingMode = false
    @State private var showStatistics = false
    @State private var showSettings = false
    @State private var editingTask: ZenTask?
    @State private var showDeleteConfirmation = false
    @State private var taskToDelete: ZenTask?
    @State private var showQuotes = true
    @State private var showArchive = false

    /// Heutige Aufgaben (gefiltert)
    private var todaysTasks: [ZenTask] {
        let today = DateHelper.startOfDay()
        let endOfToday = DateHelper.endOfDay()
        return allTasks
            .filter { $0.date >= today && $0.date <= endOfToday }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var canAddTask: Bool {
        todaysTasks.count < TaskViewModel.maxTasksPerDay
    }

    private var completedCount: Int {
        todaysTasks.filter(\.isCompleted).count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Datum und Zitat
                        headerSection

                        // Reflexions-Banner
                        if let vm = reflectionViewModel, vm.shouldShowReflectionBanner {
                            reflectionBanner
                        }

                        // Aufgaben-Liste
                        taskListSection

                        // Hinweis wenn voll
                        if !canAddTask {
                            fullDayMessage
                        }

                        Spacer(minLength: 80)
                    }
                    .padding(.top, 8)
                }

                // Floating Action Button
                if canAddTask {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            addButton
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    HStack(spacing: 16) {
                        Button {
                            showStatistics = true
                        } label: {
                            Image(systemName: "chart.bar")
                                .foregroundStyle(theme.secondaryText)
                        }
                        .accessibilityLabel("Statistiken anzeigen")

                        Button {
                            showArchive = true
                        } label: {
                            Image(systemName: "archivebox")
                                .foregroundStyle(theme.secondaryText)
                        }
                        .accessibilityLabel("Archiv anzeigen")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 16) {
                        // One-Thing-Modus
                        Button {
                            showOneThingMode = true
                        } label: {
                            Image(systemName: "eye")
                                .foregroundStyle(theme.accent)
                        }
                        .accessibilityLabel("One-Thing-Modus öffnen")
                        .disabled(todaysTasks.filter { !$0.isCompleted }.isEmpty)

                        // Einstellungen
                        Button {
                            showSettings = true
                        } label: {
                            Image(systemName: "gearshape")
                                .foregroundStyle(theme.secondaryText)
                        }
                        .accessibilityLabel("Einstellungen öffnen")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddTaskSheet { text, priority, deadline, reminderOffset, isRepeating in
                    taskViewModel?.addTask(text: text, priority: priority, deadline: deadline, reminderOffset: reminderOffset, isRepeating: isRepeating)
                }
                .presentationDetents([.medium, .large])
            }
            .sheet(item: $editingTask) { task in
                AddTaskSheet(
                    taskText: task.text,
                    priority: task.priority,
                    editingTask: task
                ) { text, priority, deadline, reminderOffset, isRepeating in
                    taskViewModel?.updateTask(task, text: text, priority: priority, deadline: deadline, reminderOffset: reminderOffset, isRepeating: isRepeating)
                }
                .presentationDetents([.medium, .large])
            }
            .fullScreenCover(isPresented: $showOneThingMode) {
                if let vm = taskViewModel {
                    OneThingView(taskViewModel: vm)
                }
            }
            .sheet(isPresented: $showReflection) {
                if let taskVM = taskViewModel, let refVM = reflectionViewModel {
                    ReflectionView(
                        taskViewModel: taskVM,
                        reflectionViewModel: refVM
                    )
                }
            }
            .sheet(isPresented: $showStatistics) {
                StatisticsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showArchive) {
                if let vm = taskViewModel {
                    ArchiveView(taskViewModel: vm)
                }
            }
            .alert("Aufgabe löschen?", isPresented: $showDeleteConfirmation) {
                Button("Löschen", role: .destructive) {
                    if let task = taskToDelete {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            taskViewModel?.deleteTask(task)
                        }
                    }
                }
                Button("Abbrechen", role: .cancel) {}
            } message: {
                Text("Diese Aufgabe wird unwiderruflich gelöscht.")
            }
            .onAppear {
                if taskViewModel == nil {
                    taskViewModel = TaskViewModel(modelContext: modelContext)
                }
                if reflectionViewModel == nil {
                    reflectionViewModel = ReflectionViewModel(modelContext: modelContext)
                }
                taskViewModel?.createRepeatingTasks()
                showQuotes = UserDefaults.standard.object(forKey: "showQuotes") as? Bool ?? true
            }
        }
    }

    // MARK: - Header (Datum + Zitat)

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Date.now.formattedDayLong)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(theme.primaryText)
                .padding(.horizontal)

            if showQuotes {
                QuoteView(quote: QuoteManager.quoteOfTheDay())
            }
        }
    }

    // MARK: - Reflexions-Banner

    private var reflectionBanner: some View {
        Button {
            showReflection = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "moon.stars.fill")
                    .font(.title3)
                    .foregroundStyle(theme.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Zeit für deine Abend-Reflexion")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(theme.primaryText)

                    Text("Schließe deinen Tag bewusst ab")
                        .font(.caption)
                        .foregroundStyle(theme.secondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(theme.accent.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .accessibilityLabel("Abend-Reflexion starten")
    }

    // MARK: - Aufgaben-Liste

    private var taskListSection: some View {
        VStack(spacing: 10) {
            // Bestehende Aufgaben
            ForEach(todaysTasks) { task in
                TaskRowView(task: task, onToggle: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        taskViewModel?.toggleCompletion(task)
                    }
                }, onTap: {
                    editingTask = task
                })
                .contextMenu {
                    Button {
                        editingTask = task
                    } label: {
                        Label("Bearbeiten", systemImage: "pencil")
                    }

                    Button {
                        taskViewModel?.moveToTomorrow(task)
                    } label: {
                        Label("Auf morgen verschieben", systemImage: "arrow.right.circle")
                    }

                    Button(role: .destructive) {
                        taskToDelete = task
                        showDeleteConfirmation = true
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        taskToDelete = task
                        showDeleteConfirmation = true
                    } label: {
                        Label("Löschen", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    Button {
                        withAnimation {
                            taskViewModel?.moveToTomorrow(task)
                        }
                    } label: {
                        Label("Morgen", systemImage: "arrow.right.circle")
                    }
                    .tint(theme.accent)
                }
            }

            // Leere Platzhalter-Slots
            let emptySlots = max(0, TaskViewModel.maxTasksPerDay - todaysTasks.count)
            ForEach(0..<emptySlots, id: \.self) { _ in
                emptySlotView
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Leerer Slot

    private var emptySlotView: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack {
                Image(systemName: "plus")
                    .font(.body)
                    .foregroundStyle(theme.secondaryText.opacity(0.4))

                Text("Aufgabe hinzufügen")
                    .font(.body)
                    .foregroundStyle(theme.secondaryText.opacity(0.4))

                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(
                        theme.secondaryText.opacity(0.15),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Neue Aufgabe hinzufügen")
    }

    // MARK: - „Tag ist geplant" Nachricht

    private var fullDayMessage: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                Text("Dein Tag ist geplant.")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.primaryText)

                Text("Fokussiere dich.")
                    .font(.caption)
                    .foregroundStyle(theme.secondaryText)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - Floating Action Button

    private var addButton: some View {
        Button {
            showAddSheet = true
            HapticManager.light()
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(
                    Circle()
                        .fill(theme.accent)
                        .shadow(color: theme.accent.opacity(0.3), radius: 8, y: 4)
                )
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
        .accessibilityLabel("Neue Aufgabe hinzufügen")
    }
}

#Preview {
    DayView()
        .modelContainer(for: [ZenTask.self, DailyReflection.self], inMemory: true)
        .environment(\.colorTheme, .forest)
}
