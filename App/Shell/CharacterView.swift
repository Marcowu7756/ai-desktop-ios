// App — flat/vector character
//
// V0 renders a flat SwiftUI character — no layered rig, no skeletal runtime.
// The view is a pure function of CharacterState: it cannot see a BrainResponse
// and it cannot ask a model anything. That is what makes behaviour reproducible.

#if canImport(SwiftUI)
import SwiftUI
import ProductCore

struct CharacterView: View {
    let state: CharacterState

    var body: some View {
        ZStack {
            face
                .offset(gestureOffset)
                .rotationEffect(.degrees(gestureRotation))
        }
        .animation(.easeInOut(duration: 0.25), value: state)
    }

    private var face: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(faceColor)
                    .frame(width: 120, height: 120)

                HStack(spacing: 34) {
                    eye
                    eye
                }

                mouth
                    .offset(y: 28)
            }

            Text(state.presence.rawValue)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var eye: some View {
        Capsule()
            .fill(Color.primary.opacity(0.8))
            .frame(width: 8, height: eyeHeight)
            .offset(x: gazeOffset)
    }

    private var eyeHeight: CGFloat {
        state.mood == .sleepy ? 4 : 10
    }

    private var mouth: some View {
        Capsule()
            .fill(Color.primary.opacity(0.7))
            .frame(width: state.presence == .speaking ? 34 : 22, height: 6)
    }

    private var faceColor: Color {
        switch state.mood {
        case .happy: return Color.yellow.opacity(0.35)
        case .sad: return Color.blue.opacity(0.25)
        case .sleepy: return Color.purple.opacity(0.22)
        case .curious: return Color.green.opacity(0.25)
        case .shy: return Color.pink.opacity(0.30)
        case .neutral: return Color.gray.opacity(0.22)
        }
    }

    private var gazeOffset: CGFloat {
        switch state.gaze {
        case .left: return -4
        case .right: return 4
        case .up, .down, .away, .user: return 0
        }
    }

    private var gestureOffset: CGSize {
        switch state.gesture {
        case .wave: return CGSize(width: 8, height: -6)
        case .cheer: return CGSize(width: 0, height: -10)
        case .dance: return CGSize(width: 6, height: 0)
        case .clasp, .cheek, .tilt, .nod, .none: return .zero
        }
    }

    private var gestureRotation: Double {
        switch state.gesture {
        case .tilt: return -6
        case .nod: return 3
        case .dance: return 5
        case .wave, .cheer, .clasp, .cheek, .none: return 0
        }
    }
}
#endif
