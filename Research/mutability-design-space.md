# Carrier mutability — design space and deferred decisions

<!--
---
version: 1.1.0
last_updated: 2026-04-25
status: DECISION
tier: 2
scope: cross-package
changelog:
  - v1.1.0 (2026-04-25): Added §"Investigation outcome (2026-04-25)" recording the
    swift-mutable-primitives / swift-mutator-primitives package investigation completed
    DEFERRED. Cross-references to relocated artifacts under swift-institute/Research/
    and swift-institute/Experiments/ added. Original DECISION on Carrier read-only
    surface unchanged.
  - v1.0.0 (2026-04-25): Initial deferral with three options (A/B/C) and option-C
    revisit triggers.
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
- ~~A `swift-mutable-primitives` package emerges in the ecosystem with a `Mutatable` protocol.~~ **Investigation completed 2026-04-25 with outcome DEFERRED** — see *Investigation outcome* below.
- Swift's KeyPath / dynamic member lookup story evolves enough that a different approach (e.g., `WritableKeyPath`-based dynamic mutation forwarding) becomes viable. Currently blocked by the same four-quadrant compatibility issues catalogued in `Research/dynamic-member-lookup-decision.md`.

## Investigation outcome (2026-04-25)

A focused investigation of option (C) — *"separate `swift-mutable-primitives` package with `Mutatable` protocol"* — was completed. The investigation iterated across three protocol shapes (full-capability with `var value: Value`; empty marker; Hasher-pattern witness type) and produced a Tier-2 academic prior-art survey and four CONFIRMED experiments before concluding **the package should NOT ship**.

**Key findings**:

- The compositional machinery is already shipped at the ecosystem layer: `swift-optic-primitives` (Lens/Prism/Iso/Affine/Traversal with composition + laws) and `swift-algebra-*` (Magma/Monoid/Group/Ring/Field/Module witnesses) cover the abstractions a Mutator package would need; substructural typing is language-level via `~Copyable`/`~Escapable`/`@_lifetime`.
- The two well-shaped gaps are small extensions to existing primitives, not a new package: (1) `Optic.Setter` for write-only mutation in `swift-optic-primitives`; (2) `Algebra.Semilattice` for CRDT-merge in the algebra family.
- The genuine academic gap (handlers for linear/borrowed state with a lifetime-bounded witness — sits between Tang–Hillerström–Lindley–Morris 2024 and Wagner et al. 2025 *BoCa*) lacks a credible second consumer per [RES-018].

**Empirical Swift findings reusable across the ecosystem**:

- `mutating _modify` is NOT a valid protocol property requirement (Swift accepts only `get`/`set` in property requirements).
- `@_lifetime(&self)` (NOT `@_lifetime(borrow self)`) on `_modify` for `~Escapable` Self.
- `WritableKeyPath<Root, Value>` carries an implicit `Root: Copyable & Escapable` constraint that propagates through protocol-extension dynamic-member subscripts — the same Q1-only constraint as for read-only `KeyPath`.

**Artifacts relocated to `swift-institute/` for cross-package reference**:

- `swift-institute/Research/mutator-type-hasher-pattern-exploration.md` (DEFERRED) — driving investigation.
- `swift-institute/Research/mutator-academic-prior-art-survey.md` (REFERENCE) — Tier-2 prior-art survey, 31 citations, 26 verified.
- `swift-institute/Research/mutator-naming-protocol-and-typealias.md` (REFERENCE) — naming spine if a future package emerges.
- `swift-institute/Research/mutator-orthogonal-vs-refinement-stance.md` (REFERENCE) — sibling-not-refinement reasoning vs Carrier.
- `swift-institute/Research/mutator-modify-across-quadrants.md` (REFERENCE) — empirical Swift findings.
- `swift-institute/Research/mutator-writable-keypath-interaction.md` (REFERENCE) — WritableKeyPath Q1-only constraint confirmation.
- `swift-institute/Experiments/hasher-pattern-mutator-isolation/` — Hasher-pattern witness viability (CONFIRMED).
- `swift-institute/Experiments/mutator-modify-across-quadrants/` — alternative-shape four-quadrant defaults (CONFIRMED).
- `swift-institute/Experiments/mutator-generic-dispatch-and-keypath/` — alternative-shape KeyPath constraint (CONFIRMED).
- `swift-institute/Experiments/mutator-dual-conformance-carrier-mutable/` — Carrier+Mutable dual conformance viability (CONFIRMED).

The deferral in this document remains in force; the investigation refined "DEFERRED, awaiting future information" into "DEFERRED, with the future-information specifications now spelled out in the relocated research."

## References

- `Research/dynamic-member-lookup-decision.md` — read-only projection's interaction with dynamic member lookup; same first-principles "capability vs noun-type" framing applies to mutation.
- `Research/carrier-vs-rawrepresentable-comparative-analysis.md` — explicit-projection stance shared with stdlib's `RawRepresentable`.
- `Research/round-trip-semantics-noncopyable-underlyings.md` — `~Copyable` Underlying's reconstruction semantics; relevant to why mutation-via-rebuild is the canonical channel.
- `Sources/Carrier Primitives/Carrier.swift` — protocol declaration; `borrowing get` only, no `_modify`.
- `swift-institute/Research/mutator-*.md` and `swift-institute/Experiments/{hasher-pattern-mutator-isolation,mutator-*}/` — investigation outcome artifacts.
