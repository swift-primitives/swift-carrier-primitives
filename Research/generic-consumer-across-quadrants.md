# Generic Consumer Across Carrier Quadrants

<!--
---
version: 1.0.0
last_updated: 2026-04-24
status: REFERENCE
tier: 1
scope: package-specific
---
-->

## Context

`carrier-vs-rawrepresentable-comparative-analysis.md` argues that Carrier's four-quadrant coverage is the load-bearing differentiator against `RawRepresentable`: Carrier admits `~Copyable` and `~Escapable` on both `Self` and `Underlying`, and a single generic signature can span all four `Copyable × Escapable` quadrants. This sketch operationalizes that claim.

The objection this addresses (c5-skeptic per `forums-review-simulation-2026-04-24.md`): "what generic code actually consumes `some Carrier<Underlying>`?" — the four-quadrant coverage claim is hand-wavy without a concrete consumer signature.

## The sketch

A witness-style consumer that projects any `Carrier`'s underlying value through a caller-supplied sink. One signature; four quadrants:

```swift
// Borrowing the Carrier, borrowing its Underlying, returning by value.
// Suppresses Copyable + Escapable on both Self and the return R, so the
// signature accepts every point in the Copyable × Escapable square.
func project<C: Carrier & ~Copyable & ~Escapable, R: ~Copyable>(
    _ carrier: borrowing C,
    through sink: (borrowing C.Underlying) -> R
) -> R {
    sink(carrier.underlying)
}
```

Four call sites, one signature:

```swift
// Q1 — Copyable & Escapable Underlying (the ordinary case):
let userID = User.ID(42)
let next = project(userID) { u in u &+ 1 }

// Q2 — ~Copyable & Escapable Underlying (resource wrappers):
let fileHandle = File.Handle(File.Descriptor(raw: 3))
let rawFd = project(fileHandle) { descriptor in descriptor.raw }

// Q3 — Copyable & ~Escapable Underlying (span-like views):
let bufferView: Buffer.View<UInt8> = .init(bytes[...])
let count = project(bufferView) { span in span.count }

// Q4 — ~Copyable & ~Escapable Underlying (scoped references):
let bufferScope: Buffer.Scope<Base> = ...
let snapshot = project(bufferScope) { ref in ref.summary() }
```

The authored conformances follow the `Nest.Name` discipline — `User.ID` (a real `User` domain plus a nested identifier wrapper for Q1), `File.Handle` over `File.Descriptor` (both siblings in the `File` namespace for Q2), and `Buffer.View` / `Buffer.Scope` (siblings under `Buffer` for Q3 and Q4). None of the carriers uses a compound name; each sits under a namespace with other inhabitants, so `[API-NAME-001a]`'s single-type-no-namespace rule is satisfied.

## Why `RawRepresentable` cannot host this

`RawRepresentable` treats `RawValue` as implicitly Copyable (pre-ownership-era protocol shape) and its `var rawValue: RawValue { get }` is a by-value getter — incompatible with both `~Copyable` Underlying (no copy available) and `~Escapable` Underlying (no lifetime scoping). Writing the equivalent generic:

```swift
// Does not compile for ~Copyable Underlying; cannot be satisfied for ~Escapable:
func project<C: RawRepresentable, R>(
    _ carrier: C,
    through sink: (C.RawValue) -> R
) -> R {
    sink(carrier.rawValue)
}
```

— excludes call sites Q2, Q3, Q4 categorically.

A pre-Carrier ecosystem solving the same problem would need one of:

- Four distinct overloads (one per quadrant), tied together by name only.
- Four sibling protocols plus a manual dispatch layer at every use site.
- Existentials with heavy-weight type erasure that discards quadrant information.

`Carrier` collapses all of that to one signature. That is the four-quadrant coverage claim, operational.

## Where the first real ecosystem consumer will appear

This sketch is the minimal demonstration. A production consumer will show up in a downstream package — e.g., a serialization witness in a future `swift-serialization-primitives` variant, a diagnostics-emission witness in `swift-diagnostic-primitives`, or a hash-projection witness in `swift-hash-primitives` — each with a signature of this shape but carrying domain-specific semantics in the sink closure. When those land, this sketch becomes the spec they satisfy; until then, it stands as the operational proof that the abstraction pays rent.

## References

- `Sources/Carrier Primitives/Carrier.swift` — the protocol declaration
- `carrier-vs-rawrepresentable-comparative-analysis.md` §Dimension 2, §Dimension 3, §Dimension 8
- `capability-lift-pattern.md` §Form-D generic algorithms — the theoretical framing of this signature shape
- `forums-review-simulation-2026-04-24.md` post 9 (c5-skeptic) — the objection this note addresses
