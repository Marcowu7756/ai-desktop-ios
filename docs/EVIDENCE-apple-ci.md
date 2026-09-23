# Evidence — Apple-side verification (GitHub-hosted macOS CI)

Date: 2026-09-23
Repository: https://github.com/Marcowu7756/ai-desktop-ios (public)
Workflow: `.github/workflows/apple-verification.yml`
Run: https://github.com/Marcowu7756/ai-desktop-ios/actions/runs/35836868145
Job IDs: core `107102308024` · app `107102308039`

Scope: **compile + simulator only.** No signing, no device install, no
developer account, no claim about Apple Intelligence on a real iPhone.

---

## 1. Environment (from the run's own log)

```
Runner image:  macos-26-arm64   (version 20260907.0351.1)
OS:            macOS 26.6.2 (25G83)
Swift:         Apple Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101)
Xcode:         26.6
SDKs:          iOS 26.5 (iphoneos26.5) · Simulator iOS 26.5 (iphonesimulator26.5)
```

Note the toolchain difference from the Windows runs: Apple Swift 6.3.3 here
versus Swift 6.4 on Windows. Both compile the same core.

## 2. Core job — the same gate, on Apple's toolchain

```
summary: 10 PASS / 0 FAIL / 0 NEEDS-APPLE-TOOLCHAIN
                          - swift build: Build complete
                          - swift test: 32 passed / 0 failed
```

Two things this establishes that Windows alone could not: the boundary gate
itself runs on macOS, and all 32 tests pass under Apple's Swift — not just
under the Windows toolchain they were written on.

## 3. App job — the SwiftUI shell, compiled for the first time

```
Created project at /Users/runner/work/ai-desktop-ios/ai-desktop-ios/App/AIDesktop.xcodeproj
** BUILD SUCCEEDED **
** TEST SUCCEEDED **
```

- `xcodebuild ... -destination 'generic/platform=iOS Simulator' build` —
  **`App/` compiles.** It had never been compiled before this run; every claim
  about the shell up to now was structural only.
- `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17' test` —
  the probe bundle ran as a unit test with `AIDesktop` as its host, which means
  the app was installed and launched in the simulator.
- `App/project.yml` is itself validated by this run: XcodeGen produced a
  project from it, and that project built.

## 4. Foundation Models probe — verbatim

```
Test Case '-[AIDesktopProbeTests.AppleProbeTests testReportAppleEnvironment]' started.
PROBE os=Version 26.5 (Build 23F77)
PROBE FoundationModels=importable
PROBE SystemLanguageModel.availability=available
Test Case '-[AIDesktopProbeTests.AppleProbeTests testReportAppleEnvironment]' passed (0.085 seconds).
	 Executed 1 test, with 0 failures (0 unexpected)
```

**This corrected an assumption.** Going in, the expectation was that Foundation
Models would report unavailable in a CI environment (the reasoning being that
Apple Intelligence needs specific hardware). It reported `available` on an
Apple Silicon `macos-26` runner, in the iOS 26.5 simulator.

Reproduced: a second, independent run on the next commit reported the same
three lines (`run=35838764039`, probe passed in 0.044s). Two runs, same result —
this is a re-runnable observation, not a one-off.

What that does and does not settle:

- It settles that `import FoundationModels` compiles against the iOS 26.5 SDK,
  and that the availability API answers rather than trapping.
- It does **not** establish that a generation request succeeds. The probe only
  asks for availability; it never asks the model for anything. That is the next
  measurable step, and it was deliberately left out of this round's scope.
- It says nothing about the iPhone 16 Pro Max. The device rung is still OPEN,
  for a different reason (signing and install, not hardware).

## 5. What this round does NOT prove

| Unverified | Needs |
|---|---|
| A model actually generates a reply | a generation test in CI or an on-device run |
| The app looks or behaves correctly | eyes, and probably a device |
| Performance / thermals / battery | a device |
| Installation on iPhone 16 Pro Max | signing + Apple Developer Program |
| ManifoldKit integration | its iOS 26 floor means the adapter package can now be resolved in CI — not attempted |
| Anything about the simulator being representative | a device comparison |

## 6. Two defects this round produced, both fixed

1. **The gate assumed Windows.** `Tests/check_boundaries.py` prepared the MSVC
   environment unconditionally, so on macOS it would have reported C9 as
   `NEEDS-TOOLCHAIN` rather than running. It now invokes the toolchain directly
   off Windows. Without this, the core job would have produced a green run whose
   only real content was "unknown".
2. **A colon broke the workflow.** The first push failed in 0 seconds: the job
   name `Core (gate: build + test)` is not a valid YAML plain scalar, because
   `: ` terminates a mapping. Both `apple-verification.yml` and `App/project.yml`
   are now parse-validated locally before pushing.

## 7. Reproducing

The workflow runs on every push to `main` and can be triggered manually
(`workflow_dispatch`). Raw output is kept as the `app-verification-raw-output`
and `core-gate-output` artifacts, and the run log itself carries per-line
timestamps.
