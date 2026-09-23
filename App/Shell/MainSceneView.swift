// App — the main scene: character + conversation + input.

#if canImport(SwiftUI)
import SwiftUI
import ProductCore

struct MainSceneView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            CharacterView(state: model.personaState.characterState)
                .frame(maxWidth: .infinity)
                .frame(height: 260)
                .background(Color.black.opacity(0.04))

            Divider()

            ConversationView(turns: model.turns)

            if let notice = model.notice {
                Text(notice)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 8) {
                TextField("Say something", text: $model.draft)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { Task { await model.send() } }

                Button("Send") {
                    Task { await model.send() }
                }
                .disabled(model.draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
    }
}
#endif
