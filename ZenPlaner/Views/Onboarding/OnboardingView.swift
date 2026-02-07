import SwiftUI

// MARK: - Onboarding (nur beim ersten Start)

struct OnboardingView: View {
    @Environment(\.colorTheme) private var theme
    @State private var currentPage = 0
    @Binding var hasCompletedOnboarding: Bool

    private let pages: [(icon: String, title: String, text: String)] = [
        (
            "leaf.fill",
            "Weniger ist mehr",
            "Zen Planer hilft dir, dich auf das Wesentliche zu fokussieren."
        ),
        (
            "hand.raised.fill",
            "Maximal 5 Aufgaben",
            "Nicht mehr. Das ist kein Bug – das ist das Feature."
        ),
        (
            "moon.stars.fill",
            "Abend-Reflexion",
            "Jeden Abend reflektierst du kurz deinen Tag. Wachstum durch Klarheit."
        )
    ]

    var body: some View {
        ZStack {
            theme.background
                .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Icon
                Image(systemName: pages[currentPage].icon)
                    .font(.system(size: 60))
                    .foregroundStyle(theme.accent)
                    .id(currentPage) // Für Animation
                    .transition(.opacity.combined(with: .scale))

                // Text
                VStack(spacing: 16) {
                    Text(pages[currentPage].title)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.primaryText)

                    Text(pages[currentPage].text)
                        .font(.body)
                        .foregroundStyle(theme.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .id(currentPage)
                .transition(.opacity)

                Spacer()

                // Seitenindikator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? theme.accent : theme.secondaryText.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }

                // Button
                Button {
                    if currentPage < pages.count - 1 {
                        withAnimation(.easeInOut(duration: 0.4)) {
                            currentPage += 1
                        }
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            hasCompletedOnboarding = true
                        }
                        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                        HapticManager.success()
                    }
                } label: {
                    Text(currentPage < pages.count - 1 ? "Weiter" : "Starten")
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(theme.accent)
                        )
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .accessibilityLabel(currentPage < pages.count - 1 ? "Weiter zur nächsten Seite" : "Onboarding abschließen und App starten")
            }
        }
    }
}

#Preview {
    OnboardingView(hasCompletedOnboarding: .constant(false))
        .environment(\.colorTheme, .forest)
}
