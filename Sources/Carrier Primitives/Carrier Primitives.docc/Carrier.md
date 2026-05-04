# ``Carrier_Primitives/Carrier``

@Metadata {
    @DisplayName("Carrier")
    @TitleHeading("Carrier Primitives")
}

A parameterized super-protocol for types that carry an `Underlying` value, optionally tagged by a phantom `Domain`.

## Overview

`Carrier.`Protocol`<Underlying>` abstracts the relationship between a phantom-typed wrapper and the value it wraps. Instances expose their underlying via a borrowing accessor and construct from an underlying via a consuming init. The protocol admits `~Copyable` and `~Escapable` suppressions on `Self`, `Domain`, and `Underlying`, covering all four quadrants of the Copyable × Escapable grid.

```swift
public protocol Carrier.`Protocol`<Underlying>: ~Copyable, ~Escapable {
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

## The four-quadrant grid

`Self` and `Underlying` independently admit or suppress `Copyable` and `Escapable`, and the protocol shape above degrades gracefully across the resulting grid — concrete conformers omit the `@_lifetime` annotations when `Underlying` is `Escapable` (Swift rejects them on Escapable results) and include them when it is `~Escapable`.

| Self | Underlying | Canonical conformer |
|------|------------|---------------------|
| `Copyable` & `Escapable` | `Copyable` & `Escapable` | Bare `Cardinal`, `Ordinal`, `Tagged<T, Int>` |
| `~Copyable` & `Escapable` | `~Copyable` & `Escapable` | `Tagged<T, MoveOnlyResource>` |
| `Copyable` & `~Escapable` | `Copyable` & `~Escapable` | Scoped Copyable references |
| `~Copyable` & `~Escapable` | `~Copyable` & `~Escapable` | `Tagged<T, Ownership.Inout<Base>>` |

The quadrant-by-quadrant conformance recipes — which annotations to include, which to omit, which getter form to use — live in <doc:Conformance-Recipes>.

## The two associated types

### `Domain`

The phantom discriminator — a type-level tag distinguishing otherwise-indistinguishable carriers of the same `Underlying`. `Tagged<User, Int>.Domain` is `User`; `Tagged<Order, Int>.Domain` is `Order`; bare `Int.Domain` (if Int conformed) would be `Never`. Generic functions can reflect on `C.Domain` to distinguish Tagged variants at the type level without any runtime overhead.

Defaults to `Never` so trivial self-carriers don't need to declare the typealias.

### `Underlying`

The wrapped value type. Marked primary via the angle-bracket syntax (`Carrier.`Protocol`<Underlying>`) so API sites can write `some Carrier.`Protocol`<Int>` per SE-0346. Suppresses Copyable and Escapable to admit move-only and lifetime-bounded wrapped values — a distinction from Swift's `RawRepresentable`, which assumes a `Copyable & Escapable` `RawValue`.

## The two requirements

### `var underlying: Underlying { @_lifetime(borrow self) borrowing get }`

Borrowing access to the carried value. The `@_lifetime(borrow self)` annotation and `borrowing get` accessor are mandatory on the protocol requirement; concrete conformers omit the annotations when `Underlying` is `Escapable` (the attributes are rejected on Escapable results), and include them when `Underlying` is `~Escapable`.

For `~Copyable` Underlying, conformers implement the getter via a `_read { yield ... }` coroutine so the stored value can be yielded by borrow without consuming. For `Copyable` Underlying, a plain `borrowing get { ... }` suffices.

### `init(_ underlying: consuming Underlying)`

The canonical construction path. Consumes an underlying value and produces a carrier wrapping it. For `Copyable` Underlying, `consuming` has no runtime cost; for `~Copyable` Underlying, the caller's value is moved into the carrier.

`@_lifetime(copy underlying)` ties the carrier's lifetime to the underlying's scope when `Underlying` is `~Escapable`. For `Escapable` Underlying, omit the annotation in the concrete conformer.

## Round-trip semantics

Reading `carrier.underlying` and rebuilding a carrier via `C(carrier.underlying)` round-trips in a specific sense that depends on `Underlying`'s copyability:

| `Underlying` | Round-trip property |
|--------------|---------------------|
| `Copyable` | Total — every underlying value round-trips identity-preservingly. |
| `~Copyable` | Weakened — the borrow returned by `.underlying` cannot itself be consumed back into `init(_:)`. The round-trip is "inspect via borrow, reconstruct from a fresh consumed value" rather than "extract identical original." |

See <doc:Round-trip-Semantics> for the full discussion. The unified protocol accepts the weakening rather than splitting into copyable-only / noncopyable-only siblings; consumers that need the identity-preserving round-trip should stick to `Copyable` Underlying conformers.

## Two conformance forms

Types join the Carrier family in two shapes depending on whether they wrap themselves or another value:

### Form 1 — Trivial self-carrier (bare types)

A bare value type is its own underlying. `Domain` defaults to `Never`:

```swift
extension Cardinal: Carrier.`Protocol` {
    typealias Underlying = Cardinal
    var underlying: Cardinal { borrowing get { self } }
    init(_ underlying: consuming Cardinal) { self = underlying }
}
```

This is the "I carry myself" case. Typical for bare arithmetic-domain primitives: Cardinal, Ordinal, Hash.Value, etc. When and if these packages adopt Carrier, they conform in this shape.

### Form 2 — Tagged carrier (phantom-tag-bearing types)

A wrapper type carries a value of a different type, with a phantom tag specifying the domain. The conformance is **unconditional** — Tagged is always a Carrier of its immediate `Underlying`, regardless of what `Underlying` is:

```swift
extension Tagged: Carrier.`Protocol`
where Tag: ~Copyable & ~Escapable, Underlying: ~Copyable & ~Escapable {
    typealias Domain = Tag
    typealias Underlying = Underlying      // immediate generic parameter
    var underlying: Underlying { _read { yield _storage } }
    init(_ underlying: consuming Underlying) {
        self.init(_unchecked: underlying)
    }
}
```

This conformance (which ships in `swift-tagged-primitives`) gives every `Tagged<Tag, V>` combination a Carrier conformance with `Domain = Tag` and `Underlying = V` (the immediate wrapped type). The single parametric extension covers the full family of Tagged specializations — including non-Carrier `Underlying` like `Ownership.Inout<Base>` (used by `Property.View`), and nested wrappers like `Tagged<X, Tagged<Y, Cardinal>>` whose `.underlying` returns `Tagged<Y, Cardinal>` (consumers reach `Cardinal` by recursing).

An earlier revision encoded a cascade — `Tagged<X, Tagged<Y, V>>.Underlying == V` (bottom-most) — by requiring `Underlying: Carrier.\`Protocol\``. That design coupled Tagged's Carrier-ness to the recursive Carrier-ness of every wrapped type and produced a name-shadowing tax on the conformance. The unconditional immediate form drops both costs in exchange for explicit consumer-side recursion when nested introspection is needed; in practice nested Tagged is rare and usually semantically structured (different domain at each level), so the recursion is honest rather than redundant.

## Generic consumers

The protocol's payoff is at API sites. Four shapes across the specificity spectrum:

```swift
// Form A: domain-axis protocol — preferred for domain-specific APIs.
// Matches bare `Cardinal` AND `Tagged<Tag, Cardinal>` (and any other
// Cardinal.`Protocol` conformer).
func align<C: Cardinal.`Protocol`>(_ c: C) -> C { ... }

// Form B: depth-axis parameterized Carrier (SE-0346 spelling).
// Matches types whose `Carrier.Underlying` is exactly `Cardinal` —
// `Tagged<Tag, Cardinal>` qualifies, but bare `Cardinal` does NOT
// (its Underlying is `UInt` post-cardinal-cascade-drop). Use only when
// the immediate-wrap depth is load-bearing; otherwise prefer Form A.
func align(_ c: some Carrier.`Protocol`<Cardinal>) -> Cardinal { ... }

// Form C: existential (loses Underlying — avoid in favor of generic)
func handle(_ c: any Carrier) { ... }

// Form D: fully generic over any Carrier
func describe<C: Carrier.`Protocol` & ~Copyable & ~Escapable>(_ c: borrowing C) -> String {
    "Carrier<\(C.Underlying.self)> with Domain \(C.Domain.self)"
}
```

Form D is the enabler — cross-Carrier algorithms become writable. Concrete near-term uses:

- **Phantom-type-aware diagnostics**: error messages that include the phantom Domain without per-type plumbing.
- **Witness-style utilities**: one Carrier-aware codec / hasher / formatter covers all conforming types.
- **Cross-Carrier conversion** (`reroot`-style): change phantom Tag while preserving value, generic in the Underlying axis.

## Why not `RawRepresentable`?

Carrier and Swift's `RawRepresentable` occupy different design spaces. See <doc:Carrier-vs-RawRepresentable> for the decision tree; the short version: `RawRepresentable`'s `init?(rawValue:)` is validating (for enum / OptionSet cases), cannot express `~Copyable` / `~Escapable` `RawValue`, has one associated type (no phantom-tag dimension), and is tied to stdlib integrations (Codable auto-synthesis, OptionSet) that don't apply at the primitives layer. Carrier complements rather than refines.

## Design decisions

### A single protocol covering all four quadrants, not split siblings

An earlier draft proposed splitting Carrier into copyable-only and `NoncopyCarrier` siblings to sidestep the round-trip weakening for `~Copyable` underlyings documented above. The final design takes the unified path: the round-trip is total for `Copyable` and weakens to "inspect-via-borrow-then-reconstruct" for `~Copyable`. Consumers opt into whichever conformance shape matches their type's characteristics; the protocol accommodates both.

### Top-level protocol with a primary associated type, not `Carrier.\`Protocol\``

Per SE-0346, `Carrier.`Protocol`<Underlying>` is declared at module scope with `Underlying` marked as a primary associated type. This enables the `some Carrier.`Protocol`<Int>` spelling at API sites. The ecosystem's nested-protocol convention (`Cardinal.\`Protocol\``) still applies to domain-specific per-type protocols; Carrier is a different shape — a super-protocol that spans the whole family.

### Trivial-self-carrier default via `extension Carrier where Underlying == Self`

Bare value types that carry themselves conform in a single `typealias Underlying = Self` line; the extension provides the `underlying` accessor and `init(_:)`. The default uses `_read { yield self }` rather than `borrowing get { self }` so the same extension works whether `Self` admits copying or suppresses it. The `Carrier Primitives Standard Library Integration` target ships 28 stdlib conformances of this shape (`Int`, `String`, `Bool`, `Span`, `MutableSpan`, …) in a single-line-per-type form — including the four `~Escapable` span types via the Q3 default extension.

## Topics

### Creating a Carrier

- ``Carrier/init(_:)``

### Accessing the Underlying

- ``Carrier/underlying``

### Associated Types

- ``Carrier/Domain``
- ``Carrier/Underlying``
