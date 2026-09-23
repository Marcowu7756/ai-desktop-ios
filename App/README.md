# App target

SwiftUI sources for the V0 shell. **There is no committed Xcode project.**

## Why

A `.pbxproj` cannot be validated here: this environment is Windows with no Xcode.
Committing an unverified project file would be worse than committing none — it
looks like a working app that nobody has opened.

## Creating the project on a Mac

```sh
brew install xcodegen
cd App
xcodegen generate
open AIDesktop.xcodeproj
```

Or create an iOS App target manually in Xcode and add the package at the
repository root as a local SwiftPM dependency (products: `ProductCore`,
`BrainKit`).

## Platform floor

The package currently declares iOS 17 / macOS 14. This deliberately does **not**
match ManifoldKit's iOS 26 floor — see `docs/ADR-0002`. If the project later
decides to adopt ManifoldKit, that decision has to be made explicitly, because
adding it to the root `Package.swift` would raise the floor of everything.

## What this target must never do

`CompositionRoot.swift` is the only file that picks a brain adapter. It may
import `BrainKit`, but it must never name a ManifoldKit type.
