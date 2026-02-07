import SwiftUI

// MARK: - Farbiger Prioritäts-Punkt

struct PriorityDot: View {
    @Environment(\.colorTheme) private var theme
    let priority: Priority

    /// Größe des Punktes
    var size: CGFloat = 10

    var body: some View {
        Circle()
            .fill(theme.color(for: priority))
            .frame(width: size, height: size)
            .accessibilityLabel("Priorität: \(priority.displayName)")
    }
}

#Preview {
    HStack(spacing: 16) {
        PriorityDot(priority: .high)
        PriorityDot(priority: .medium)
        PriorityDot(priority: .low)
    }
    .environment(\.colorTheme, .forest)
    .padding()
}
