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

### 3b. Apple-side verification — part 1 done (2026-09-23)

Run: https://github.com/Marcowu7756/ai-desktop-ios/actions/runs/35836868145
Full record: `docs/EVIDENCE-apple-ci.md`

Verified by the CI workflow:

| Item | Result |
|---|---|
| The gate itself on macOS | `10 PASS / 0 FAIL / 0 NEEDS-APPLE-TOOLCHAIN` |
| `ProductCore` / `BrainKit` under Apple Swift 6.3.3 | `swift test: 32 passed / 0 failed` |
| **`App/` compiling for the iOS Simulator** | `** BUILD SUCCEEDED **` (Xcode 26.6, iOS 26.5 SDK) |
| The app host launching in a simulator | `** TEST SUCCEEDED **` — probe ran with `AIDesktop` as host |
| `App/project.yml` being valid | XcodeGen produced a project that built |
| `import FoundationModels` against the iOS 26.5 SDK | `PROBE FoundationModels=importable` |
| `SystemLanguageModel` availability | `PROBE SystemLanguageModel.availability=available` |

The last line **corrected an assumption**: the expectation was that a CI machine
would report `unavailable`. It did not. See the evidence document for what that
does and does not settle.

### 3c. Still unverified

| Item | Why |
|---|---|
| A generation request actually succeeding | the probe only asks availability; it never asks the model for anything |
| The app's appearance and behaviour | nobody has looked at it; no screenshots were taken |
| Performance, thermals, battery | needs a device |
| ManifoldKit integration | its iOS 26 floor can now be resolved in CI (Xcode 26 is present) — not attempted |
| `FoundationModelsBrainAdapter` | still a guarded stub that throws `notImplemented` |
| Installation on iPhone 16 Pro Max | device is **identified and eligible** (A18 Pro, iOS 27); the rung is blocked by signing, not hardware |

### 3d. ManifoldKit platform-floor check — still the open procedure

Only step 4 below remains unrun; steps 1–3 are now covered by CI.

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

## 5. Repository publication and CI — AUTHORIZED AND EXECUTED (2026-09-23)

Previously held on the rule that *being cheap is not the same as being
authorized*. The Owner then authorized publication with one explicit constraint:
**only this project may be published.** The parent directory holds several
unrelated projects (`setv-*`, `diag-minimal`, `probe-dispatch-*`), so isolation
was the point of the constraint.

What was done:

- `git init` inside this directory only, so the repository cannot reach a
  sibling project; verified against `git ls-files` (49 files, all in-tree).
- a secret scan across every published file before the first push: no keys.
- `work/*.log` excluded, because the generated log embeds local absolute paths.
- **one** public repository: https://github.com/Marcowu7756/ai-desktop-ios

The first round below was scoped to exactly this and nothing more — it now
contains the results:

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

Still out of scope and not authorized by this: device installation, code
signing, and an Apple Developer Program membership.

Gate discipline carries over unchanged: a green CI run satisfies **Gate 1 only**.
Gate 2 still requires reproducible raw Xcode / Simulator output.
