# AI Desktop iOS — V0 scaffold

Read in this order:

| Document | Contents |
|---|---|
| [ADR-0001](ADR-0001-frozen-layers.md) | frozen layers, the one-way dependency rule, why it is enforced mechanically |
| [ADR-0002](ADR-0002-manifoldkit-positioning.md) | ManifoldKit as candidate adapter, the platform-floor trap, options A/B/C |
| [V0-SCOPE](V0-SCOPE.md) | what V0 proves, what is in, what is out, acceptance checks |
| [OPEN-ITEMS](OPEN-ITEMS.md) | open questions, and what can only be verified on a Mac |
| [EVIDENCE-windows-swift-6.4](EVIDENCE-windows-swift-6.4.md) | toolchain, environment prerequisites, real build/test results, and what they do not prove |
| [EVIDENCE-apple-ci](EVIDENCE-apple-ci.md) | GitHub-hosted macOS run: App compiled, simulator probe, Foundation Models availability |

## Layout

```text
Package.swift              root manifest, dependencies: [] (stays empty)
ProductCore/               Shell / Persona / State / Memory / Action / turn loop / protocols
BrainKit/                  adapters (mock, remote, foundation models)
App/                       SwiftUI sources + XcodeGen spec (no committed .pbxproj)
Tests/                     Swift tests + the boundary gate
Adapters/ManifoldAdapter/  separate local package, OFF, the only place ManifoldKit may appear
docs/                      this documentation
```

## Running the boundary gate

```sh
python Tests/check_boundaries.py
```

Exit code 0 means every boundary holds. The gate also performs the real compile
and test pass (it prepares the MSVC environment itself), so a run reports
`swift build: Build complete` and the executed test counts. If no toolchain is
present it reports that plainly instead of inventing a pass.

## Status of the code

`ProductCore`, `BrainKit` and the tests have been compiled and executed on
Windows with Swift 6.4 — see the evidence document. The SwiftUI `App/` target and
everything iOS-specific have **not** been compiled or run, and cannot be here.
Treat this as a verified core with an unverified shell, not as a working app.

## Two gates for any change to ProductCore or BrainKit

```text
edit -> swift build -> swift test -> python Tests/check_boundaries.py
```

**Gate 1 — result.** `PASS` before anything else proceeds. `FAIL` means stop and
fix — do not lower the gate to make a change fit. `NEEDS-TOOLCHAIN` is **not** a
pass; if the toolchain or its prerequisites (MSVC `link.exe` via the VS developer
shell, plus `SDKROOT`) are missing, the result is *unknown*, and unknown must be
treated as unverified.

**Gate 2 — evidence.** A result only counts if there is real, citable execution
output behind it:

- Written `PASS` is not a substitute for output.
- If the script or tool being cited does not exist, any claimed `PASS` is void.
- Reproducible evidence beats an agent's stated status.

This rule exists because it already happened: a claimed `8/8 PASS` was once
reported with no execution behind it — the script it cited did not exist on
disk. That incident is now a standing gate rather than a cautionary anecdote.

Note the limit of Gate 2 honestly: a log file proves *a* run happened, not *when*
or *by whom*. The real defence is reproducibility — the reviewer re-runs the same
command. That is why recorded evidence must be quoted raw, including the run's
own timestamps, which a fresh run will not reproduce.

### Apple-side simulation

Simulating an Apple environment is **forbidden as a verification substitute**.
SwiftUI, the iOS target, Foundation Models, and device behaviour stay `OPEN`
until a real macOS / Xcode / iOS environment opens them. Filling that gap with
stubs would convert an honest unknown into a false pass.
