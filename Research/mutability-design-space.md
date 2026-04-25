# Carrier mutability — design space and deferred decisions

<!--
---
version: 1.0.0
last_updated: 2026-04-25
status: DECISION
tier: 2
scope: cross-package
---
-->

## Context

`Carrier`'s `var underlying: Underlying` requires only `borrowing get` — read-only projection. The trivial-self default extensions (Q1/Q2/Q3/Q4) provide `_read { yield self }` and consuming `init(_:)`, no `_modify`. The question of whether to add a mutable variant has come up repeatedly during 0.1.x design and is captured here so it isn't relitigated and so the right shape (when it does ship) has been pre-figured.

## Question

Should the package add a generic mutation surface — typically a refining protocol `Carrier.Mutable` (or similar) that lets generic functions write `func f(_ c: inout some C) { c.underlying.foo = bar }`?

## Analysis

### Why read-only is the right default

1. **Phantom-typed identity guarantee.** Most Carrier conformers are phantom-typed wrappers — `User.ID`, `Order.ID`, `Cardinal`, `Ordinal`. The wrapper's purpose is to keep its underlying value distinct at the type level. Mutation through `.underlying` would let consumers mutate the raw value in place without going through `init(_:)`, eroding the construct-via-the-type's-API boundary that the wrapper exists to enforce.

2. **RawRepresentable precedent.** Stdlib's `RawRepresentable.rawValue` is `get`-only. `Research/carrier-vs-rawrepresentable-comparative-analysis.md` records that Carrier and RawRepresentable occupy non-substitutable design spaces but share the explicit-projection stance. Adding a mutable projection without explicit ceremony would break that consistency.

3. **Mutation channel is `init(_:)`.** The protocol's mutation channel is reconstruction: consume the carrier, take ownership of the underlying, mutate it externally, rebuild via `init(_ underlying:)`. For Copyable Underlyings this is cheap. For ~Copyable Underlyings it requires the consume-rebuild dance but matches the ownership semantics of the carried type.

### Why a refinement protocol named `Carrier.Mutable` is structurally awkward

Swift doesn't allow nesting protocols inside protocols. To get the dotted form `Carrier.Mutable`, the package would need to convert `Carrier` from a top-level protocol to an enum namespace + `Carrier.\`Protocol\``, mirroring the swift-institute `Type.\`Protocol\`` convention used by Cardinal, Ordinal, Hash.

That convention works for those types because they're *noun-types* — Cardinal is both a value type AND a namespace via the back-tick trick. There's a real concrete Cardinal you instantiate; the protocol is a refinement that lets generic algorithms work over Cardinal-shaped values.

Carrier has no concrete `Carrier` value. Forcing it into a namespace shell purely to nest `Mutable` underneath would create a pure-namespace enum — not a noun-type, just punctuation around the dotted form. The asymmetry with Tagged (a real concrete generic type) is jarring: Tagged is a noun, Carrier is a capability, and the naming convention shouldn't pretend they're analogous.

### Three honest options when mutation demand surfaces

| Option | Shape | Cost |
|---|---|---|
| **(A) Don't add it.** | Mutation is per-conformer concrete API. Generic consumers needing mutation work with concrete types. | Zero. Current state. |
| **(B) Top-level `MutableCarrier` (compound name).** | Refining protocol with stdlib-precedent compound name (cf. `MutableCollection`). [API-NAME-001] explicitly exempts capability-variant protocols (Mutable, Bidirectional, …) from the noun-only rule. | Single new top-level protocol; consumers refine. |
| **(C) Separate `swift-mutable-primitives` package with `Mutatable` protocol.** | A standalone capability protocol orthogonal to Carrier. Carrier-conforming types that also need generic mutation dispatch conform to `Mutatable` independently. The two protocols compose without either having to know about the other. | New package, but the abstraction stays cleanly factored. |

### First-principles read

Carrier is a *capability* — "this type carries a value." Mutation is a *different capability* — "this type's stored state can be modified." These are orthogonal axes:

- A Carrier conformer that's a value-typed phantom wrapper (User.ID): doesn't need generic mutation dispatch — concrete `var raw: Int` field is fine.
- A Carrier conformer that's a `~Copyable` resource handle: mutation is the concrete API of the resource, not a generic protocol concern.
- A type that needs to be a Carrier AND is mutable: the two capabilities are independent; a single conformance to a hypothetical `Mutatable` protocol expresses the second without coupling to Carrier.

This points to **option (C) as the principled future shape** if mutation demand crystallizes. A `swift-mutable-primitives` package owning a `Mutatable` protocol would provide:

```swift
public protocol Mutatable<Value>: ~Copyable, ~Escapable {
    associatedtype Value: ~Copyable & ~Escapable
    var value: Value {
        @_lifetime(borrow self) borrowing get
        @_lifetime(borrow self) mutating _modify
    }
}
```

Types that are both Carrier AND Mutatable conform to both:

```swift
extension MyMutableContainer: Carrier, Mutatable {
    typealias Underlying = X
    typealias Value = X
    // ...
}
```

The two protocols don't refine each other — they compose. Generic algorithms that need both: `func f<T: Carrier & Mutatable>(_ t: inout T) where T.Underlying == T.Value { ... }`.

This is a future-work direction, not a 0.1.x commitment.

## Outcome

**Status**: DECISION — `Carrier` remains read-only at v0.1.x. No `Carrier.Mutable` refinement is added. Generic mutation dispatch is deferred indefinitely; revisited only on concrete consumer demand.

**Rationale**:

1. The phantom-typed identity guarantee that motivates Carrier in the first place argues against generic mutation through `.underlying`.
2. The `Carrier.Mutable` dotted form requires a namespace refactor that creates an empty enum shell — silly given Carrier is a pure capability protocol with no concrete noun-type backing (unlike Cardinal/Ordinal/Hash).
3. Stdlib-precedent compound naming (`MutableCarrier`) is acceptable as a future option but not needed pre-emptively.
4. The principled long-term shape — orthogonal `Mutatable` protocol in a separate package — keeps Carrier and mutation cleanly factored. This is recorded for future work, not implemented now.

**Revisit triggers**:

- A concrete consumer surfaces a genuine need for `func f<C: ???>(_ c: inout C) { c.underlying.foo = bar }` generic dispatch. At that point, the design space narrows from speculative to evidence-based.
- A `swift-mutable-primitives` package emerges in the ecosystem with a `Mutatable` protocol. At that point, integrating Carrier with it (either via dual conformance on shared types, or via a refining `Carrier & Mutatable`-style protocol) becomes concrete.
- Swift's KeyPath / dynamic member lookup story evolves enough that a different approach (e.g., `WritableKeyPath`-based dynamic mutation forwarding) becomes viable. Currently blocked by the same four-quadrant compatibility issues catalogued in `Research/dynamic-member-lookup-decision.md`.

None of these triggers is active as of 2026-04-25.

## References

- `Research/dynamic-member-lookup-decision.md` — read-only projection's interaction with dynamic member lookup; same first-principles "capability vs noun-type" framing applies to mutation.
- `Research/carrier-vs-rawrepresentable-comparative-analysis.md` — explicit-projection stance shared with stdlib's `RawRepresentable`.
- `Research/round-trip-semantics-noncopyable-underlyings.md` — `~Copyable` Underlying's reconstruction semantics; relevant to why mutation-via-rebuild is the canonical channel.
- `Sources/Carrier Primitives/Carrier.swift` — protocol declaration; `borrowing get` only, no `_modify`.
