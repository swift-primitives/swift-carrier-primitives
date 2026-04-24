# Carrier Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Unified super-protocol for phantom-typed value wrappers — `Carrier<Underlying>` abstracts Cardinal, Ordinal, Hash.Value, Tagged, and the rest of the primitives layer's value-carrying types, across all four `Copyable × Escapable` quadrants.

---

## Motivation

Swift's stdlib already has `RawRepresentable` — a protocol that looks structurally similar: one associated type, one accessor, one init. `Carrier<Underlying>` differs on three load-bearing axes:

- It admits `~Copyable & ~Escapable` on both `Self` and `Underlying`. `RawRepresentable` was designed before ownership language features existed and cannot express these shapes.
- It carries a second associated type, `Domain`, for phantom-type discrimination. `RawRepresentable` has no phantom dimension — `UserID` and `OrderID` both wrapping `Int` are indistinguishable under its constraint.
- It uses `consuming` / `borrowing` ownership annotations at the protocol level, rather than the implicit by-value semantics of `init?(rawValue:)` / `var rawValue: RawValue { get }`.

These differences aren't decoration — they're what lets the ecosystem's `Tagged<Tag, V>`, `Cardinal`, `Ordinal`, `Hash.Value`, and `~Copyable` resource wrappers share one super-protocol that `RawRepresentable` cannot host. See `Research/carrier-vs-rawrepresentable-comparative-analysis.md` for the full nine-dimension comparison and the explicit non-substitution decision.

---

## Key Features

- **One protocol, four quadrants** — `Carrier<Underlying>` admits `~Copyable` and `~Escapable` suppression on `Self`, `Domain`, and `Underlying`. A single declaration covers `Copyable & Escapable`, `~Copyable & Escapable`, `Copyable & ~Escapable`, and `~Copyable & ~Escapable` conformers. Earlier design drafts had proposed splitting into a `Copyable`-only protocol + a `NoncopyCarrier` sibling; the final design unifies them.
- **Zero external dependencies** — Ships the protocol only. Conformances for ecosystem types (Tagged, Cardinal, Ordinal, Hash.Value, etc.) live in each conforming type's home package. Carrier Primitives itself has no upstream packages in its dependency graph. (Internal target-to-target dependencies within the package — the Integration target re-exports the main target; Test Support re-exports both — are not external dependencies.)
- **Primary associated type** — `Carrier<Underlying>` per SE-0346 enables the parameterized-constraint spelling `some Carrier<Int>` at API sites.
- **Two axes of discrimination** — `Domain` (phantom tag, defaults to `Never`) + `Underlying` (wrapped value type). Generic consumers can reflect on both metatypes for phantom-type-aware diagnostics, cross-Carrier conversion, and witness-based serialization.
- **Trivial self-carrier default** — `extension Carrier where Underlying == Self` provides the `underlying` getter and `init(_:)` for free, so trivial self-carriers (types that carry themselves) declare conformance with a single `typealias Underlying = Self` line.
- **Stdlib integration** — The `Carrier Primitives Standard Library Integration` target conforms 24 stdlib primitive types to Carrier as trivial self-carriers, so bare stdlib values reach `some Carrier<Int>` / `some Carrier<String>` / etc. APIs without wrapping. See the Architecture section for the full list.
- **Foundation-free** — Primitives-layer per `[PRIM-FOUND-001]`; no Foundation imports.

---

## Shape

```swift
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    associatedtype Domain: ~Copyable & ~Escapable = Never
    associatedtype Underlying: ~Copyable & ~Escapable

    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
```

---

## Quick Start

### Define a phantom-typed carrier

```swift
import Carrier_Primitives

public enum User {}
public enum Order {}

struct UserID: Carrier {
    typealias Domain = User
    typealias Underlying = UInt64

    var _raw: UInt64
    var underlying: UInt64 { borrowing get { _raw } }
    init(_ underlying: consuming UInt64) { self._raw = underlying }
}

struct OrderID: Carrier {
    typealias Domain = Order
    typealias Underlying = UInt64

    var _raw: UInt64
    var underlying: UInt64 { borrowing get { _raw } }
    init(_ underlying: consuming UInt64) { self._raw = underlying }
}
```

`UserID` and `OrderID` both wrap `UInt64`, but their `Domain` associated types differ. Generic code can distinguish them without any runtime cost.

### Write a generic function over any Carrier of Int

```swift
// SE-0346 parameterized-constraint form — accepts any Carrier whose
// Underlying is Int, regardless of Domain.
func printInt(_ c: borrowing some Carrier<Int>) {
    print(c.underlying)
}

// Fully generic — accepts any Carrier at all.
func describe<C: Carrier & ~Copyable & ~Escapable>(
    _ c: borrowing C
) -> String {
    "Carrier<\(C.Underlying.self)> with Domain \(C.Domain.self)"
}
```

Without Carrier, each of these forms would require a per-type protocol or hand-rolled overload. With Carrier, one signature covers the whole family.

### Conform a ~Copyable resource

```swift
struct FileHandle: ~Copyable { var fd: Int32 }

struct FileHandleCarrier: ~Copyable, Carrier {
    typealias Underlying = FileHandle

    var _storage: FileHandle

    // ~Copyable storage requires `_read { yield }` to yield by borrow
    // without consuming.
    var underlying: FileHandle {
        _read { yield _storage }
    }

    init(_ underlying: consuming FileHandle) {
        self._storage = underlying
    }
}
```

The `_read` coroutine satisfies the protocol's `borrowing get` requirement for `~Copyable` Underlying. `@_lifetime` annotations are omitted because `FileHandle` is Escapable (the attribute is rejected on Escapable results); they are required only for `~Escapable` Underlying.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-carrier-primitives.git", from: "0.1.0")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Three library products, zero external dependencies.

| Product | Target | Purpose |
|---------|--------|---------|
| `Carrier Primitives` | `Sources/Carrier Primitives/` | The `Carrier<Underlying>` protocol + `extension Carrier where Underlying == Self` default implementation for trivial self-carriers. |
| `Carrier Primitives Standard Library Integration` | `Sources/Carrier Primitives Standard Library Integration/` | Conforms 24 stdlib primitive types to Carrier as trivial self-carriers. See the stdlib conformance table below. |
| `Carrier Primitives Test Support` | `Tests/Support/` | Re-exports the main targets for test consumers. |

Source files:

| File | Purpose |
|------|---------|
| `Carrier.swift` | The `Carrier<Underlying>` protocol declaration — all four quadrants covered via `~Copyable & ~Escapable` suppression on `Self`, `Domain`, and `Underlying`. |
| `Carrier+Trivial.swift` | The `extension Carrier where Underlying == Self` default — `_read { yield self }` getter + `init(_ underlying: consuming Self)` init for types that carry themselves. Makes trivial self-carrier conformances a one-line `typealias`. |

Per `[MOD-015]` consumer-import-precision, import the narrowest product you need. If you only want the protocol (e.g., declaring conformances for your own types), import `Carrier Primitives`. If you want the protocol AND the stdlib conformances, import `Carrier Primitives Standard Library Integration` (which re-exports the main target via `@_exported public import`).

### Stdlib conformances shipped by the SLI target

| Category | Types |
|----------|-------|
| Native-width integers | `Int`, `UInt` |
| Sized integers (8-bit) | `Int8`, `UInt8` |
| Sized integers (16-bit) | `Int16`, `UInt16` |
| Sized integers (32-bit) | `Int32`, `UInt32` |
| Sized integers (64-bit) | `Int64`, `UInt64` |
| 128-bit integers | `Int128`, `UInt128` (SE-0425) |
| Floating-point | `Double`, `Float`, `Float16` |
| Boolean | `Bool` |
| Text / Unicode | `String`, `Substring`, `Character`, `Unicode.Scalar`, `StaticString` |
| Time | `Duration` |
| Object identity | `ObjectIdentifier` |
| Uninhabited | `Never` (type-level conformance; no value can exist) |

Every conformance is a trivial self-carrier with `Domain = Never` (the default) and `Underlying = Self`. The default `extension Carrier where Underlying == Self` in the main target provides `underlying` and `init(_:)`, so each per-type conformance collapses to a single `typealias Underlying = Self` line.

### Conformance ownership

`swift-carrier-primitives` is the canonical owner of the stdlib-type Carrier conformances. Downstream packages that want `some Carrier<Int>` reach for bare stdlib values depend on the `Carrier Primitives Standard Library Integration` product rather than declaring `Int: Carrier` themselves — there is one canonical conformance per stdlib type, sourced from this package.

This model sidesteps the SE-0364 retroactive-conformance hazard: if two transitive dependencies both declared `Int: Carrier` independently, Swift's module system would warn and the resulting conformance selection would be undefined behavior across module boundaries. By centralizing the stdlib conformances in this integration target, the module graph has exactly one source of truth.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |
| Swift Embedded | Supported |

---

## Related Packages

**Used By**:

- [swift-tagged-primitives](https://github.com/swift-primitives/swift-tagged-primitives) — `Tagged<Tag, V>` is the canonical free generic implementation of Carrier. `Tagged: Carrier` conformance lives in tagged-primitives per the ecosystem convention (conformances of a type to a foreign protocol live in the conformer's home package).
- [swift-cardinal-primitives](https://github.com/swift-primitives/swift-cardinal-primitives) — Cardinal (and `Tagged<T, Cardinal>`) candidates for `Carrier<Cardinal>` adoption.
- [swift-ordinal-primitives](https://github.com/swift-primitives/swift-ordinal-primitives) — Ordinal candidate for `Carrier<Ordinal>` adoption.
- [swift-hash-primitives](https://github.com/swift-primitives/swift-hash-primitives) — Hash.Value candidate for `Carrier<Hash.Value>` adoption.

**Related research** (not a dependency, but a companion):

- [swift-ownership-primitives](https://github.com/swift-primitives/swift-ownership-primitives) — hosts `Ownership.Borrow.\`Protocol\`` and the self-projection-default pattern, the orthogonal meta-pattern to Carrier. See `Research/capability-lift-pattern.md` and `swift-ownership-primitives/Research/self-projection-default-pattern.md`.

**External dependencies**: none.

---

## Research Corpus

This package ships with the full research record in `Research/`:

- `capability-lift-pattern.md` (v1.1.0, RECOMMENDATION) — the pattern characterization + Option A/B/C analysis + Tagged-as-canonical-Carrier framing.
- `capability-lift-pattern-primitives.md` — primitives-layer view.
- `capability-lift-pattern-academic-foundations.md` (Tier 3) — 11 primary citations (Reynolds 1983, Wadler 1989, Hinze 2003, Cheney-Hinze 2003, Yallop-White 2014, Atkey 2009, Cardelli-Wegner 1985, Wadler-Blott 1989, Leijen-Meijer 1999, Carette-Kiselyov-Shan).
- `capability-lift-pattern-academic-foundations-primitives.md` — primitives-layer slice of the academic foundations.
- `carrier-vs-rawrepresentable-comparative-analysis.md` (DECISION, 2026-04-24) — nine-dimension comparison of Carrier vs Swift stdlib's RawRepresentable, concluding non-substitutable.

Plus the empirical anchor:

- `Experiments/capability-lift-pattern/` — six variants V0–V5 probing the pattern's recipe, super-protocol unification options, API broadening, and limits. CONFIRMED on Swift 6.3.1.

---

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
