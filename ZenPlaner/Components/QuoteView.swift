import SwiftUI

// MARK: - Zitat-Anzeige

struct QuoteView: View {
    @Environment(\.colorTheme) private var theme
    let quote: Quote

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\u{201E}\(quote.text)\u{201C}")
                .font(.subheadline)
                .fontWeight(.light)
                .italic()
                .foregroundStyle(theme.secondaryText)
                .lineSpacing(4)

            Text("– \(quote.author)")
                .font(.caption)
                .foregroundStyle(theme.secondaryText.opacity(0.7))
        }
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Zitat: \(quote.text). Von \(quote.author)")
    }
}

#Preview {
    QuoteView(quote: Quote(text: "Einfachheit ist die höchste Stufe der Vollendung.", author: "Leonardo da Vinci"))
        .environment(\.colorTheme, .forest)
        .padding()
}
