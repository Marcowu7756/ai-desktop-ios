// App — conversation surface. Text only in V0.

#if canImport(SwiftUI)
import SwiftUI
import ProductCore

struct ConversationView: View {
    let turns: [CompanionTurn]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 8) {
                ForEach(Array(turns.enumerated()), id: \.offset) { _, turn in
                    HStack(alignment: .top, spacing: 8) {
                        Text(turn.characterState.mood.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 56, alignment: .leading)

                        Text(turn.presentation)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding()
        }
    }
}
#endif
