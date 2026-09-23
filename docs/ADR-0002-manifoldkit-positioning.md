# ADR-0002 — ManifoldKit is a candidate adapter, not an architectural floor

Status: **accepted — option B chosen (2026-09-23)**
Date: 2026-09-23

## Context

ManifoldKit (`github.com/ManifoldKit/ManifoldKit`, MIT) is the only candidate
from the audit that is designed to be depended upon rather than forked. Its
facts, independently verified read-only:

| Fact | Value |
|---|---|
| `Package.swift` platforms | `.iOS("26.0")`, `.macOS("26.0")` |
| `swift-tools-version` | 6.1 |
| Latest release | v0.79.0 (2026-09-20), still pushed 2026-09-22 |
| License | MIT |
| Scale | 8 stars, 1 fork, single primary maintainer |
| Stated policy | deliberately sits on the n-1 OS generation |
| Docs conflict | README badge says iOS 18+ / macOS 15+; manifest and prose say 26 |

Ruling: **the manifest wins — the floor is iOS 26.**

## Decision (2026-09-23): option B

```text
Root package (ProductCore / BrainKit / App)   platform-neutral: iOS 17 / macOS 14
Adapters/ManifoldAdapter                      declares iOS 26 itself, in its own Package.swift
                                              NOT referenced by the root package
```

So iOS 26 is an **adapter-local constraint**, paid only if that adapter is ever
enabled:

```text
ProductCore     platform-independent
BrainProtocol   product-owned
BrainKit        product-owned
ManifoldAdapter optional
ManifoldKit     optional
iOS 26          adapter-local constraint
```

Option A was rejected because writing iOS 26 into the root manifest lets a
candidate dependency's platform requirement contaminate the whole product
graph — the opposite of "ManifoldKit is a candidate adapter, not an architectural
dependency". Option C was rejected because forking a dependency that has not yet
passed any real Apple-toolchain verification would promote a candidate into a
product fact prematurely.

### The limit of this decision — do not self-deceive

"Adapter-local" is currently a claim about the **manifest**, not about
**resolution**. If a real SwiftPM / Xcode resolution shows the App target still
inherits iOS 26 through the dependency closure, this ADR is wrong on that point
and must be corrected with the measured result — not defended with the phrase
"adapter-local". That check is step 4 of the procedure in `docs/OPEN-ITEMS.md`,
and it must be run with the adapter referenced, not merely sitting unused.

## The trap this ADR exists to prevent

The decision "accept ManifoldKit's iOS 26 floor, but do not make it the
architecture floor" does **not** hold automatically in SwiftPM. A platform floor
declared by a dependency is a hard gate on the whole graph: once ManifoldKit is
in the root `Package.swift`, the package cannot resolve below iOS 26, and
**removing it later does not lower the floor back**.

So the floor must be kept out of the root manifest by construction:

```text
Package.swift (root)      dependencies: []        <- empty, and stays empty
Adapters/ManifoldAdapter  its own Package.swift, depends on ManifoldKit
                          NOT referenced by the root package
```

Enabling it is a configuration change (point the App at the adapter package);
disabling it is deleting that one reference. Neither touches ProductCore.

## Options if the floor question is ever reopened

| Option | Effect | Cost | Status |
|---|---|---|---|
| A. Accept iOS 26 | ManifoldKit becomes the first-choice adapter | Smallest device coverage; the floor contaminates the whole graph | rejected |
| **B. Adapter-local iOS 26** | Root stays neutral; the constraint is paid only when the adapter is enabled | The Brain layer is all ours for now | **chosen** |
| C. Fork the manifest | Lower floor by editing their `Package.swift` | Permanent fork maintenance on an unverified candidate | rejected |

## What must not be done

- Do not add ManifoldKit to the root `Package.swift`, ever.
- Do not copy code from `ManifoldKit/manifold-apps` — that repository has **no
  license**.
- Do not let a ManifoldKit dependency, import, or type appear outside
  `Adapters/ManifoldAdapter`. (`BrainAdapterID.manifoldKit` in BrainKit is a
  policy label with no dependency behind it — that is permitted, and it is only
  reachable if an adapter registers itself.)
