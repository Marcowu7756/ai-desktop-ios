# ADR-0001 — Frozen layers and the one-way dependency rule

Status: **accepted (frozen)**
Date: 2026-09-23

## Decision

The product is split into two layers with a one-way dependency:

```text
ProductCore        BrainKit
  Shell              adapters
  Persona            └── MockBrainAdapter
  CharacterState        FoundationModelsAdapter   (unimplemented, guarded)
  State                 RemoteLLMBrainAdapter     (unimplemented transport)
  Memory                ManifoldAdapter           (separate local package, OFF)
  Action boundary
  BrainProtocol
  structured types
        ^                    |
        └────────────────────┘
        BrainKit -> ProductCore, never the reverse
```

Two rules, both mechanically enforced by `Tests/check_boundaries.py`:

1. **ProductCore has no external dependencies.** Its `Package.swift` target
   dependencies are empty, and no file under `ProductCore/` imports an inference
   library.
2. **No provider type crosses the boundary.** `BrainResponse`, `CompanionTurn`,
   `CharacterState`, `PersonaState`, `ActionIntent`, `MemoryEvent` and
   `BrainProtocol` are defined by us. Adapters receive `BrainInput` and return
   `BrainResponse`; nothing else is exchanged.

## The line is trust, not naming

`BrainResponse` and `CompanionTurn` are not two names for one thing. They sit on
opposite sides of a trust boundary:

```text
Brain
  ↓
BrainResponse       untrusted / provider-facing — candidates, raw strings
  ↓
PresentationMapper  validate + normalise
  ↓
CompanionTurn       ProductCore-owned / closed vocabulary
  ↓
Persona + Action mapping
```

Persona never consumes raw provider output, and a provider's types never travel
backwards into ProductCore. That property is the asset; the names are incidental.
(Confirmed and closed by the Owner on 2026-09-23 — keep the two-stage pipeline.)

## Why this is more than a convention

`ManifoldKit.Type` may exist only inside `Adapters/ManifoldAdapter`. If a
provider's type appears in a return value, it walks up the call stack and the
rule is gone — so the wire shape (`BrainWireTurn`, in BrainKit) is what adapters
are required to produce, and ProductCore never sees it either.

The same reasoning applies to the character: **AI never drives the animation.**
`PresentationMapper` is the only producer of `CompanionTurn`, and it is
deterministic. `CharacterState` is the only thing a renderer may read. A model
that outputs `"backflip"` gets its entire gesture ignored, not guessed at —
see `CharacterState.applying(candidate:)`.

## Consequences

- Deleting ManifoldKit entirely leaves ProductCore compiling. That is the whole
  point of the split, and it is why the root `Package.swift` ships with an empty
  `dependencies:` array.
- Adding a brain later is a registration in `CompositionRoot`, plus a policy
  value — not a change to Persona or State.
- The turn loop belongs to ProductCore (`CompanionSession`), not to the shell.
  Anything the shell would otherwise have to sequence lives here instead, where
  the gate can reach it. The shell renders results; it does not decide them.
- The cost we accept: adapters duplicate a little mapping code. That is cheaper
  than a leaked type.

## Note on field order

`CharacterStateCandidate` places mood / gaze / gesture **before** the spoken
line, and `BrainWireTurn` mirrors that order. This is deliberate and inherited
from a prior validated pattern: an adapter that emits fields progressively can
commit the face and pose before the sentence is finished.
