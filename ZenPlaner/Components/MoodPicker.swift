import SwiftUI

// MARK: - Stimmungs-Auswahl (5 Emojis)

struct MoodPicker: View {
    @Binding var selectedMood: Mood
    @Environment(\.colorTheme) private var theme

    var body: some View {
        HStack(spacing: 16) {
            ForEach(Mood.allCases, id: \.self) { mood in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedMood = mood
                    }
                    HapticManager.selection()
                } label: {
                    VStack(spacing: 4) {
                        Text(mood.emoji)
                            .font(.system(size: 32))
                            .scaleEffect(selectedMood == mood ? 1.2 : 1.0)

                        Text(mood.displayName)
                            .font(.caption2)
                            .foregroundStyle(
                                selectedMood == mood
                                    ? theme.primaryText
                                    : theme.secondaryText
                            )
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedMood == mood ? theme.accent.opacity(0.15) : .clear)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(mood.displayName) auswählen")
                .accessibilityAddTraits(selectedMood == mood ? .isSelected : [])
            }
        }
    }
}

#Preview {
    MoodPicker(selectedMood: .constant(.good))
        .environment(\.colorTheme, .forest)
        .padding()
}
