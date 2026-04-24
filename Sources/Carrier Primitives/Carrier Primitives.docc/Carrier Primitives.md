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

0.1.0 is the final release for this package. The protocol shape above is frozen; no further API is planned. Adoption by individual types (`Tagged: Carrier`, `Cardinal: Carrier`, etc.) lives in each type's home package, not here.

### Package design decisions

- **Zero external dependencies.** Carrier Primitives ships the protocol only; conformances live in conforming types' home packages per the ecosystem pattern (see `swift-tagged-primitives` for how this is arranged for Tagged-shape types).
- **`Carrier<Underlying>` is a top-level protocol, not `Carrier.\`Protocol\``.** The research doc `capability-lift-pattern.md` recommends the parameterized form per SE-0346, which enables `some Carrier<Int>` spelling at API sites.
- **A single unified protocol covering all four quadrants, not split protocols.** Earlier research had proposed a separate `NoncopyCarrier` for `~Copyable` Underlying (per the V5b round-trip-weakening observation). The final design takes the unified path: the round-trip is total for Copyable Underlying and weakens to "inspect-via-borrow-then-reconstruct" for `~Copyable`. Consumers opt into whichever conformance shape matches their type's characteristics; the protocol accommodates both.
- **Foundation-free.** Required per `[PRIM-FOUND-001]`.

## Topics

### Core Protocol

- ``Carrier``

### Concepts

- <doc:Understanding-Carriers>
