# Evidence — Windows Swift 6.4 local verification

Date: 2026-09-23
Scope: **ProductCore / BrainKit / Tests only.** This is not an iOS verification.

---

## 1. Toolchain

```
Swift version 6.4 (swift-6.4-RELEASE)
Target: x86_64-unknown-windows-msvc
Build config: +assertions

installer: swift-6.4.0-RELEASE-windows10.exe (2000.7 MB)
sha256:    76169a85bcba82854a0cd8f9655ffb74b3758d60c35a245457510095f2823c03
           (matches the official winget manifest hash)
path:      %LOCALAPPDATA%\Programs\Swift\Toolchains\6.4.0+Asserts\usr\bin\swift.exe
```

## 2. Environment prerequisites (both were required)

The toolchain alone is not enough on Windows:

| Requirement | Why | How it was satisfied |
|---|---|---|
| MSVC `link.exe` on PATH | Swift fails with `toolchain is invalid: could not find CLI tool link` | `Microsoft.VisualStudio.DevShell.dll` → `Enter-VsDevShell -arch=x64 -host_arch=x64` (VS Build Tools 2022, MSVC 14.44) |
| `SDKROOT` environment variable | otherwise `unable to load standard library for target 'x86_64-unknown-windows-msvc'` | read from the user-scope variable the installer creates |

`Tests/check_boundaries.py` sets up both itself, so C9 reproduces from a bare shell.

## 3. Result

```
swift build   ->  Build complete
swift test    ->  32 tests passed / 0 failed

ProductCoreTests bundle = 17
    ActionBoundaryTests 3 · CompanionSessionTests 7 · PresentationMapperTests 4 · SessionMemoryTests 3
BrainKitTests bundle    = 15
    BrainRegistryTests 6 · BrainWireDecoderTests 5 · MockBrainAdapterTests 4
```

The suite was 19 tests at the first run and grew to 32 when the turn loop moved
into ProductCore and the brain registry got its own tests. Both numbers are real
runs; the earlier figures in any older copy of this document are superseded.

Re-runnable as one command (it prepares the MSVC environment itself):

```sh
python Tests/check_boundaries.py
```

Reports `10 PASS / 0 FAIL / 0 NEEDS-APPLE-TOOLCHAIN`, with C9 doing a real build
and a real test run. Full output of the most recent run:
`work/swift-build-test.log` — rewritten by every run, so the numbers that matter
are reproduced verbatim below.

## 3b. Raw output (verbatim, most recent run)

```
Build complete! (33.25 secs)     <- first ever cold build
Build complete! (8.24 secs)      <- this run
```

```
Test Suite 'ActionBoundaryTests' passed at 2026-09-23 07:29:23.890
	 Executed 3 tests, with 0 failures (0 unexpected)
Test Suite 'CompanionSessionTests' passed at 2026-09-23 07:29:23.892
	 Executed 7 tests, with 0 failures (0 unexpected)
Test Suite 'PresentationMapperTests' passed at 2026-09-23 07:29:24.000
	 Executed 4 tests, with 0 failures (0 unexpected)
Test Suite 'SessionMemoryTests' passed at 2026-09-23 07:29:24.001
	 Executed 3 tests, with 0 failures (0 unexpected)
	 Executed 17 tests, with 0 failures (0 unexpected)     <- ProductCoreTests bundle
Test Suite 'BrainRegistryTests' passed at 2026-09-23 07:29:24.257
	 Executed 6 tests, with 0 failures (0 unexpected)
Test Suite 'BrainWireDecoderTests' passed at 2026-09-23 07:29:24.259
	 Executed 5 tests, with 0 failures (0 unexpected)
Test Suite 'MockBrainAdapterTests' passed at 2026-09-23 07:29:24.260
	 Executed 4 tests, with 0 failures (0 unexpected)
	 Executed 15 tests, with 0 failures (0 unexpected)     <- BrainKitTests bundle
```

The timestamps are the run's own. A re-run produces different ones — that is the
point: this is a record of an execution, not a claim.

Reproduction scripts kept in `work/`: `fetch_swift.ps1` (resumable 16-part
downloader for the 2 GB installer, needed if this ever has to be rebuilt) and
`probe_parallel.ps1` (the connection-count / transport throughput probe that
established ~1 MB/s was the network ceiling here).

## 4. What this proves

The four V0 acceptance checks in `docs/V0-SCOPE.md` are no longer aspirational:

1. `ProductCore` depends on no inference library — manifest and sources.
2. Dependency direction is `BrainKit → ProductCore`, one-way.
3. Structured types are ours and live in ProductCore.
4. A minimal adapter turns input into our structured type, and the output
   survives ProductCore's mapper.

It also covers the parts that carry the architecture's weight:

- the **turn loop** (`CompanionSession`): no brain configured is surfaced rather
  than faked, a failing brain commits nothing, a refused action does not swallow
  the turn, memory events reach the store, and an unrecognised mood carries over
  instead of resetting;
- the **deterministic mapper** and closed-vocabulary clamping;
- the **fail-closed action boundary**;
- the **strict wire decoder**;
- the **brain registry**: an adapter named by policy but absent from the registry
  yields nothing, rather than silently substituting something the policy did not
  enable.

## 5. What this does NOT prove

| Unverified | Needs |
|---|---|
| `App/` compiling | Xcode / macOS — the SwiftUI target is not part of the SwiftPM package |
| Anything about the iOS target | Xcode / macOS |
| Foundation Models capability | an eligible device with Apple Intelligence |
| ManifoldKit integration | Xcode 26 + a real `swift package resolve` (see `docs/OPEN-ITEMS.md`) |
| Real interaction | a running app |

Windows Swift is a verification instrument here. It is **not** a product
platform constraint: nothing in the architecture was changed to suit it.

Note the direction of travel: the turn loop was moved *out* of the SwiftUI shell
*into* ProductCore precisely so that this gate covers it. The unverifiable
surface got smaller; nothing was built to make Windows scores look better.

That move also means `App/AppModel.swift` and `App/CompositionRoot.swift` were
edited this round. **Those edits are themselves unverified** — no Xcode has
compiled them. Thinning the shell reduces how much logic sits in the unverified
zone; it does not raise the shell's verification status.

## 6. Warnings observed (not failures)

1. `WinSDK.swiftmodule: reference to type 'wchar_t' broken by a context change`
   — emitted by the Windows SDK module shipped with the toolchain, not by our
   code. It appears because `WinSDK` was built with Swift 5.10 while the
   invocation uses 6.4. Harmless here; worth re-checking if it ever becomes an
   error.
2. `unable to create symbolic link at .build/debug ... error 512`
   — Windows developer mode is off, so SwiftPM cannot create its convenience
   symlink. The build still completed.

## 7. Defects this verification caught

1. **Manifest argument order.** `Package.swift` declared
   `.target(name:path:dependencies:)`; Swift requires `dependencies:` before
   `path:`, so it would not have compiled. Check **C10** now fails the gate if any
   target declaration reorders those arguments — a class of error that is
   invisible without a compiler.
2. **The turn loop lived in the unverified layer.** It was in
   `App/AppModel.swift`, i.e. the one place the gate cannot reach. Moving it into
   `ProductCore/CompanionSession.swift` brought it under test; the 13 new tests
   passed on first compile.
