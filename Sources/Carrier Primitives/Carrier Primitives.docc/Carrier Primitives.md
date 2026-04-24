# ``Carrier_Primitives``

@Metadata {
    @DisplayName("Carrier Primitives")
    @TitleHeading("Swift Institute — Primitives Layer")
}

A unified super-protocol for phantom-typed value wrappers.

## Overview

`Carrier Primitives` ships ``Carrier``, a parameterized protocol abstracting over types that carry a wrapped `Underlying` value with an optional phantom `Domain` tag. Cardinal, Ordinal, Hash.Value, Tagged, and similar value-carrying primitives all fit the pattern; Carrier is the canonical abstraction under which they compose.

The protocol covers all four `Copyable × Escapable` quadrants in a single declaration — both the carrier and its underlying can independently admit or suppress Copyable and Escapable. This matches the four concrete shapes that appear in the primitives layer:

| Self | Underlying | Canonical conformer |
|------|------------|---------------------|
| `Copyable` & `Escapable` | `Copyable` & `Escapable` | Bare `Cardinal`, `Ordinal`, `Tagged<T, Int>` |
| `~Copyable` & `Escapable` | `~Copyable` & `Escapable` | `Tagged<T, MoveOnlyResource>` |
| `Copyable` & `~Escapable` | `Copyable` & `~Escapable` | Scoped Copyable references |
| `~Copyable` & `~Escapable` | `~Copyable` & `~Escapable` | `Tagged<T, Ownership.Inout<Base>>` |

### Shape

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

`Domain` defaults to `Never` so bare self-carriers (trivial case: the type carries itself) can skip the typealias. Tagged-family carriers override `Domain` with the phantom tag (e.g., `Tagged<UserTag, Int>.Domain == UserTag`), which lets generic consumers of `some Carrier<Int>` discriminate between Tagged variants at the type level.

### Status

0.1.0 is the final release for this package. The protocol shape above is frozen; no further API is planned. Adoption by ecosystem types (`Tagged: Carrier`, `Cardinal: Carrier`, etc.) lives in each type's home package. Stdlib numeric and primitive type conformances ship in `Carrier Primitives Standard Library Integration` (see §"Products" below).

### Products

| Product | Purpose |
|---------|---------|
| `Carrier Primitives` | The `Carrier<Underlying>` protocol + `extension Carrier where Underlying == Self` default for trivial self-carriers. |
| `Carrier Primitives Standard Library Integration` | Conforms 14 stdlib primitive types (`Int`, `UInt`, `Int8`–`Int64`, `UInt8`–`UInt64`, `Double`, `Float`, `Bool`, `String`) to Carrier as trivial self-carriers. Bare stdlib values reach `some Carrier<Int>` / `some Carrier<String>` / etc. APIs without any explicit wrapping. |
| `Carrier Primitives Test Support` | Re-exports the main targets for test consumers. |

### Package design decisions

- **Zero external dependencies.** Carrier Primitives ships the protocol, the trivial-self-carrier default, and stdlib conformances — no upstream packages. Ecosystem conformances (Tagged, Cardinal, Ordinal, etc.) live in conforming types' home packages per the ecosystem pattern (see `swift-tagged-primitives` for how this is arranged for Tagged-shape types).
- **`Carrier<Underlying>` is a top-level protocol, not `Carrier.\`Protocol\``.** The research doc `capability-lift-pattern.md` recommends the parameterized form per SE-0346, which enables `some Carrier<Int>` spelling at API sites.
- **A single unified protocol covering all four quadrants, not split protocols.** Earlier research had proposed a separate `NoncopyCarrier` for `~Copyable` Underlying (per the V5b round-trip-weakening observation). The final design takes the unified path: the round-trip is total for Copyable Underlying and weakens to "inspect-via-borrow-then-reconstruct" for `~Copyable`. Consumers opt into whichever conformance shape matches their type's characteristics; the protocol accommodates both.
- **Trivial self-carrier default via `extension Carrier where Underlying == Self`.** Reduces per-type conformance to a single `typealias Underlying = Self` line. The default uses `_read { yield self }` (rather than `borrowing get { self }`) to work in the generic extension context where Self's copyability is suppressed.
- **Stdlib integration as a separate target.** Consumers who only want the protocol (e.g., to declare their own type's conformance without pulling in Int/String conformances) import `Carrier Primitives`; consumers who want the full stdlib integration import `Carrier Primitives Standard Library Integration`. Per `[MOD-015]` consumer-import-precision.
- **Foundation-free.** Required per `[PRIM-FOUND-001]`.

## Topics

### Core Protocol

- ``Carrier``

### Concepts

- <doc:Understanding-Carriers>
