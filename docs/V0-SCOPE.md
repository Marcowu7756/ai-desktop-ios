# V0 scope

## The only thing V0 has to prove

```text
Launch
  ↓
Persona appears
  ↓
user speaks / types
  ↓
BrainProtocol
  ↓
structured response (BrainResponse — candidates, raw strings)
  ↓
ProductCore validation + PresentationMapper (deterministic)
  ↓
CompanionTurn → CharacterState
  ↓
speech / text presentation
```

The open question in V0 is **the product loop, not the size of the tech stack.**

## In scope

| Piece | Where | State |
|---|---|---|
| SwiftUI Shell (main scene) | `App/Shell` | sources only, no Xcode project |
| Flat / vector character | `App/Shell/CharacterView.swift` | deterministic function of `CharacterState` |
| Conversation surface | `App/Shell/ConversationView.swift` | text only |
| Persona + CharacterState | `ProductCore` | done |
| BrainProtocol + structured types | `ProductCore` | done |
| Turn loop (input → brain → mapper → memory → action) | `ProductCore/CompanionSession.swift` | done, 7 tests — deliberately **not** in the shell |
| At least one Brain adapter | `BrainKit/MockBrainAdapter.swift` | done, deterministic |
| Local session memory | `ProductCore/SessionMemory.swift` | in-memory only, nothing persisted |
| Deterministic presentation mapper | `ProductCore/PresentationMapper.swift` | done |
| Action boundary | `ProductCore/ActionBoundary.swift` | **fails closed**, no executor |
| JudgmentBackend | `ProductCore/JudgmentBackend.swift` | protocol seam only, **zero implementations** |

## Explicitly out of V0

Jev · Live2D · Widget · Live Activity · background proactive behaviour ·
multiple personas · DigitalSelf integration · SETV integration.

This is not caution for its own sake. Widget and Live Activity are not UI work:
they are separate targets with their own entitlements, App Group, and background
refresh budget. Putting them in V0 would keep V0 from ever shipping.

## Acceptance checks for this scaffold

1. `ProductCore` depends on no inference library.
2. Dependency direction is `BrainKit → ProductCore`, one-way.
3. Structured types are defined by us, in ProductCore.
4. One minimal adapter turns an input into our structured type.

All four are now executed, not asserted. `Tests/check_boundaries.py` verifies
1–3 structurally and runs the real compile + test pass; check 4 is covered by
`MockBrainAdapterTests`, which drives input through the adapter and then through
`PresentationMapper`.

```text
swift build -> Build complete
swift test  -> 19 passed / 0 failed
gate        -> 10 PASS / 0 FAIL / 0 NEEDS-APPLE-TOOLCHAIN
```

See `docs/EVIDENCE-windows-swift-6.4.md` for the toolchain, the environment
prerequisites, and — just as important — the list of things this does **not**
prove.
