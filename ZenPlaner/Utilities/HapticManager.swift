import SwiftUI

// MARK: - Haptic-Feedback-Verwaltung

struct HapticManager {
    /// UserDefaults-Key für die Haptic-Einstellung
    private static let hapticEnabledKey = "hapticFeedbackEnabled"

    /// Prüft, ob Haptic Feedback aktiviert ist
    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: hapticEnabledKey) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: hapticEnabledKey)
    }

    /// Haptic Feedback ein-/ausschalten
    static func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: hapticEnabledKey)
    }

    /// Leichtes Feedback (z. B. beim Abhaken einer Aufgabe)
    @MainActor static func light() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    /// Mittleres Feedback (z. B. beim Löschen)
    @MainActor static func medium() {
        guard isEnabled else { return }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    /// Erfolgs-Feedback (z. B. Aufgabe erledigt)
    @MainActor static func success() {
        guard isEnabled else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    /// Auswahl-Feedback (z. B. Prioritätswechsel)
    @MainActor static func selection() {
        guard isEnabled else { return }
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
