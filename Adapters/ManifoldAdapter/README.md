# ManifoldAdapter (OFF)

The only directory in this repository where the name `ManifoldKit` is allowed.

## Why it is a separate package

ManifoldKit's `Package.swift` declares `.iOS("26.0")` / `.macOS("26.0")`. A
platform floor declared by a dependency is a hard gate on the entire dependency
graph, and — importantly — **removing the dependency later does not lower the
floor back**. If it were added to the root manifest, our own floor would become
iOS 26 permanently, whether or not we kept using it.

Keeping it here means:

```text
enable  = reference this package from the App
disable = remove that reference
```

A configuration change, not a refactor. See `docs/ADR-0002`.

## Status

Not built, not verified, not referenced by anything. `ManifoldBrainAdapter`
throws `BrainError.notImplemented` on purpose.

## Before enabling it

1. On a Mac, read `Package.swift` of ManifoldKit and confirm the real platform
   floor and the required toolchain (its manifest declares `swift-tools-version:
   6.1`).
2. Run its `quickStart()` to confirm Foundation Models actually works on the
   target device.
3. Map its output onto `BrainWireTurn` inside this package only.
4. Do **not** copy code from `ManifoldKit/manifold-apps` — that repository has no
   license.
