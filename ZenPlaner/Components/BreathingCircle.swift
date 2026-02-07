import SwiftUI

// MARK: - Atem-Animation (pulsierender Kreis)

struct BreathingCircle: View {
    @Environment(\.colorTheme) private var theme
    @State private var isExpanded = false

    /// Dauer eines Atemzugs (ein/aus) in Sekunden
    var breathDuration: Double = 4.0

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    gradient: Gradient(colors: [
                        theme.accent.opacity(0.15),
                        theme.accent.opacity(0.05),
                        theme.accent.opacity(0.0)
                    ]),
                    center: .center,
                    startRadius: 20,
                    endRadius: 150
                )
            )
            .scaleEffect(isExpanded ? 1.05 : 0.95)
            .opacity(isExpanded ? 0.8 : 0.4)
            .animation(
                .easeInOut(duration: breathDuration)
                .repeatForever(autoreverses: true),
                value: isExpanded
            )
            .onAppear {
                isExpanded = true
            }
            .accessibilityHidden(true)
    }
}

#Preview {
    BreathingCircle()
        .frame(width: 300, height: 300)
        .environment(\.colorTheme, .forest)
}
