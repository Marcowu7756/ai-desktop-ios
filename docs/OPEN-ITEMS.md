# Open items

Status (2026-09-23): **Windows Swift implementation verification = CLOSED.**
**Apple-side verification = OPEN.** The two are kept strictly apart — nothing
verified on Windows is extrapolated to iOS, SwiftUI, Foundation Models, or a
device.

Nothing here is silently decided. Each remaining item is waiting on an Apple
platform, not on effort.

## 1. `CompanionTurn` vs `BrainResponse` — CLOSED (2026-09-23)

The architecture discussion described the structured turn two ways:

```text
CompanionTurn { mood, gaze, gesture, speech, remember }
BrainResponse { presentation, characterState, memoryEvents, optionalActionIntent }
```

These were **not** silently merged. The scaffold implements them as two stages
of one pipeline:

| Type | Layer | Carries | Trust |
|---|---|---|---|
| `BrainResponse` | produced by an adapter | `characterStateCandidate` (raw strings), `presentation`, `memoryEvents`, `actionIntent` | untrusted |
| `CompanionTurn` | produced only by `PresentationMapper` | `characterState` (closed enums), `presentation`, `memoryEvents`, `actionIntent` | validated |

So `mood/gaze/gesture → speech → remember` is the shape of the *candidate*, and
the resolved turn is what the product commits.

**Owner ruling (2026-09-23): keep the two-stage pipeline. No structural change.**
The distinction that matters is the trust boundary, not the naming — see
`docs/ADR-0001-frozen-layers.md`.

## 2. Platform floor — CLOSED (2026-09-23)

**Owner ruling: option B.** The root package stays platform-neutral (iOS 17 /
macOS 14); `Adapters/ManifoldAdapter` carries iOS 26 as an adapter-local
constraint and is not referenced by the root package. See `docs/ADR-0002`.

One part of this is still unproven and must not be assumed: whether a real
SwiftPM / Xcode resolution keeps iOS 26 out of the App target's closure. That is
step 4 of the procedure below.

## 3. Verification status

### 3a. Verified locally — Windows Swift 6.4 (2026-09-23)

| Item | Result |
|---|---|
| `ProductCore` compiles | `Build complete` |
| `BrainKit` compiles | `Build complete` |
| All non-SwiftUI tests | **19 passed / 0 failed** |
| Boundary gate | 10 PASS / 0 FAIL / 0 NEEDS-APPLE-TOOLCHAIN |

Full record: `docs/EVIDENCE-windows-swift-6.4.md`. Reproduce with
`python Tests/check_boundaries.py`.

This required installing the Swift toolchain plus two environment prerequisites
(MSVC `link.exe` via the VS developer shell, and the `SDKROOT` variable). The
gate performs both setup steps itself.

### 3b. Still unverified — needs macOS / a device

| Item | Why |
|---|---|
| `App/` compiling as an iOS app | needs Xcode; no `.pbxproj` is committed on purpose |
| Anything about the iOS target | needs Xcode / macOS |
| ManifoldKit `quickStart()` behaviour | needs Xcode 26 |
| Foundation Models on a real device | device is **identified and eligible**: iPhone 16 Pro Max (A18 Pro) on iOS 27 — the rung is blocked by build/sign access, not by hardware |
| `FoundationModelsBrainAdapter` | currently a guarded stub that throws `notImplemented` |

Windows Swift is a verification instrument, **not** a product platform
constraint: no architecture decision was changed to accommodate it. The
SwiftUI sources remain unexecuted and are marked as such.

### Mac validation procedure

Run in this order and keep the raw output of each step. Until step 4 passes,
there is no evidence that this project builds.

```sh
# 1. package builds, and the unverified tests actually run
swift build
swift test

# 2. does the floor stay clean while the adapter is NOT referenced?
swift package dump-package

# 3. does the App target compile?
brew install xcodegen
cd App && xcodegen generate && open AIDesktop.xcodeproj
#   build the AIDesktop scheme for an iOS Simulator destination

# 4. the claim that actually needs checking:
#    reference Adapters/ManifoldAdapter, then resolve again and observe whether
#    iOS 26 now appears in the App target's closure
swift package resolve
```

**How to read step 4.** If iOS 26 enters the closure *when the adapter is
referenced*, that is the expected and acceptable cost of enabling it — but it
must then be recorded in `ADR-0002` as a measured fact, replacing the current
"adapter-local" wording. If the floor rises even while the adapter is **not**
referenced, that is a defect in this scaffold and ADR-0002 is simply wrong.

Only after that, try ManifoldKit's `quickStart()` to see whether Foundation
Models works on the target device.

## 4. Deliberate non-decisions

- **Persistence**: session memory is in-memory only. Storage format is a V1
  question.
- **Naming**: the protocol is named `BrainProtocol` to match the frozen
  vocabulary, not Swift's usual convention (`Brain`).
- **`affinity`**: present in `PersonaState` as a placeholder counter, not used
  by any rule yet. It earns its place only when something consumes it.

## 5. Repository publication and CI — NOT AUTHORIZED (2026-09-23)

Owner ruling: **stay on HOLD.** Do not:

- create a git repository
- push to GitHub
- make a repository public
- write or run a CI workflow

Being cheap is not the same as being authorized. The macOS CI path is the
cheapest way to open the Apple-side build rung, and it is deliberately not being
taken yet.

If this is ever authorized, the first round is scoped to exactly this and
nothing more:

```text
real macOS / Xcode
      ↓
xcodebuild
      ↓
iOS Simulator
      ↓
SwiftUI App launch / test
      ↓
SystemLanguageModel availability probe
      ↓
raw output + timestamp
```

Device installation, code signing, and a developer account stay out of scope
until the free, account-less rungs are verified.

Gate discipline carries over unchanged: a green CI run satisfies **Gate 1 only**.
Gate 2 still requires reproducible raw Xcode / Simulator output.
