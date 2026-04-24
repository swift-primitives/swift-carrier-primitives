# Carrier Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Unified super-protocol for phantom-typed value wrappers — `Carrier<Underlying>` abstracts Cardinal, Ordinal, Hash.Value, Tagged, and the rest of the primitives layer's value-carrying types, across all four `Copyable × Escapable` quadrants.

---

## Key Features

- **One protocol, four quadrants** — `Carrier<Underlying>` admits `~Copyable` and `~Escapable` suppression on `Self`, `Domain`, and `Underlying`. A single declaration covers `Copyable & Escapable`, `~Copyable & Escapable`, `Copyable & ~Escapable`, and `~Copyable & ~Escapable` conformers. Earlier design drafts had proposed splitting into a `Copyable`-only protocol + a `NoncopyCarrier` sibling; the final design unifies them.
- **Zero dependencies** — Ships the protocol only. Conformances for ecosystem types (Tagged, Cardinal, Ordinal, Hash.Value, etc.) live in each conforming type's home package. Carrier Primitives itself has no upstream dependencies.
- **Primary associated type** — `Carrier<Underlying>` per SE-0346 enables the parameterized-constraint spelling `some Carrier<Int>` at API sites.
- **Two axes of discrimination** — `Domain` (phantom tag, defaults to `Never`) + `Underlying` (wrapped value type). Generic consumers can reflect on both metatypes for phantom-type-aware diagnostics, cross-Carrier conversion, and witness-based serialization.
- **Trivial self-carrier default** — `extension Carrier where Underlying == Self` provides the `underlying` getter and `init(_:)` for free, so trivial self-carriers (types that carry themselves) declare conformance with a single `typealias Underlying = Self` line.
- **Stdlib integration** — The `Carrier Primitives Standard Library Integration` target conforms Swift's numeric primitives (`Int`, `UInt`, `Int8`–`Int64`, `UInt8`–`UInt64`, `Double`, `Float`), `Bool`, and `String` to Carrier as trivial self-carriers. Bare stdlib values reach `some Carrier<Int>` / `some Carrier<String>` / etc. APIs without wrapping.
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
| `Carrier Primitives Standard Library Integration` | `Sources/Carrier Primitives Standard Library Integration/` | Conforms 14 stdlib numeric and primitive types to Carrier as trivial self-carriers — `Int`, `UInt`, the sized integer family (`Int8`–`Int64`, `UInt8`–`UInt64`), `Double`, `Float`, `Bool`, `String`. |
| `Carrier Primitives Test Support` | `Tests/Support/` | Re-exports the main targets for test consumers. |

Source files:

| File | Purpose |
|------|---------|
| `Carrier.swift` | The `Carrier<Underlying>` protocol declaration — all four quadrants covered via `~Copyable & ~Escapable` suppression on `Self`, `Domain`, and `Underlying`. |
| `Carrier+Trivial.swift` | The `extension Carrier where Underlying == Self` default — `_read { yield self }` getter + `init(_ underlying: consuming Self)` init for types that carry themselves. Makes trivial self-carrier conformances a one-line `typealias`. |

Per `[MOD-015]` consumer-import-precision, import the narrowest product you need. If you only want the protocol (e.g., declaring conformances for your own types), import `Carrier Primitives`. If you want the protocol AND the stdlib conformances, import `Carrier Primitives Standard Library Integration` (which re-exports the main target via `@_exported public import`).

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

## Final-Release Framing

**0.1.0 is this package's final release.** The protocol shape above is the locked-in API; no changes or additions are planned. Downstream packages adopt the pattern at their own cadence by adding `extension MyType: Carrier` conformances in their own repositories.

This framing reflects the protocol's completeness for its purpose: a single super-protocol over phantom-typed value wrappers, covering all four quadrants, with a minimal surface (one primary associated type, one defaulting associated type, one borrowing getter, one consuming init). The research corpus in `Research/` characterizes the pattern and documents what was considered and rejected for the final shape.

---

## Related Packages

**Used By**:

- [swift-tagged-primitives](https://github.com/swift-primitives/swift-tagged-primitives) — `Tagged<Tag, V>` is the canonical free generic implementation of Carrier. `Tagged: Carrier` conformance lives in tagged-primitives per the ecosystem convention (conformances of a type to a foreign protocol live in the conformer's home package).
- [swift-cardinal-primitives](https://github.com/swift-primitives/swift-cardinal-primitives) — Cardinal (and `Tagged<T, Cardinal>`) candidates for `Carrier<Cardinal>` adoption.
- [swift-ordinal-primitives](https://github.com/swift-primitives/swift-ordinal-primitives) — Ordinal candidate for `Carrier<Ordinal>` adoption.
- [swift-hash-primitives](https://github.com/swift-primitives/swift-hash-primitives) — Hash.Value candidate for `Carrier<Hash.Value>` adoption.

**Related research** (not a dependency, but a companion):

- [swift-ownership-primitives](https://github.com/swift-primitives/swift-ownership-primitives) — hosts `Ownership.Borrow.\`Protocol\`` and the self-projection-default pattern, the orthogonal meta-pattern to Carrier. See `Research/capability-lift-pattern.md` and `swift-ownership-primitives/Research/self-projection-default-pattern.md`.

**Dependencies**: none.

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
