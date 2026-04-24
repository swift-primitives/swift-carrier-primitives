# Carrier vs RawRepresentable — Comparative Analysis

<!--
---
version: 1.0.0
last_updated: 2026-04-24
status: DECISION
tier: 2
scope: cross-package
---
-->

## Context

`Carrier<Underlying>` in `swift-carrier-primitives` is a new super-protocol (declared 2026-04-24) abstracting phantom-typed value wrappers. `Swift.RawRepresentable` in the stdlib is a longstanding protocol abstracting types with a canonical raw-value form. Structurally they appear similar — both expose a wrapped value, both permit constructing from that value — and a reasonable design question is whether the two should be related (Carrier refining RawRepresentable, Carrier replacing RawRepresentable for our use cases, or Carrier being a Foundation-independent sibling).

This analysis compares them across nine dimensions. The outcome is a DECISION: Carrier and RawRepresentable occupy distinct, non-substitutable design spaces; neither subsumes nor refines the other, and they should stay structurally independent even when they happen to coexist on the same concrete type.

**Trigger**: [RES-001] Investigation — a concrete design question prompted by shipping `Carrier<Underlying>` in 2026-04-24: can Carrier's role be served by RawRepresentable instead, avoiding a new protocol? Answering requires a systematic dimensional comparison rather than pattern-matching on surface similarity.

**Scope**: cross-package. The comparison informs adoption decisions across every ecosystem package that carries phantom-typed wrappers (tagged-primitives, cardinal-primitives, ordinal-primitives, hash-primitives, property-primitives) and clarifies the positioning against Swift stdlib. Placed in swift-carrier-primitives/Research/ because the decision is about Carrier's identity vis-à-vis RawRepresentable.

**Tier**: 2 (Standard) — cross-package, documents a structural decision that affects how consumers reason about the relationship between Carrier and a stdlib precedent.

## Prior Art

- `comparative-analysis-pointfree-swift-tagged.md` (DECISION, 2026-02-26, in `swift-tagged-primitives/Research/`) established that Tagged deliberately does NOT conform to `RawRepresentable`. §3.1 of that doc records the rationale: `RawRepresentable` implies a failable initializer, introduces two construction paths with different semantics, and constrains `RawValue: Copyable` in a way that blocks `~Copyable` raw values. The present analysis extends that type-level finding to the super-protocol level (Carrier) and examines whether the picture changes when abstracting over all Carrier conformers rather than one specific type.
- `capability-lift-pattern.md` (RECOMMENDATION, v1.1.0, in this package's Research/) §"Tagged as the canonical Carrier" frames Tagged as the free generic implementation of Carrier. That framing makes the RawRepresentable question sharper: if RawRepresentable could play the Carrier role, Tagged could conform to it too — but Tagged's rejection of RawRepresentable per §3.1 indicates the structural mismatch is fundamental, not cosmetic.

## Question

1. **Structural match**: does `Carrier<Underlying>` describe the same concept as `RawRepresentable`, with Underlying = RawValue?
2. **Subset / superset**: could Carrier refine RawRepresentable (carrier is-a raw-representable with extra requirements), or could RawRepresentable refine Carrier (raw-representable is-a carrier with extra requirements)?
3. **Substitutability**: if both existed in isolation on a concrete type, could a consumer treat them interchangeably?
4. **Should ecosystem types conform to both**? If a type is both a Carrier and naturally RawRepresentable-shaped, does the double conformance add value or friction?

## Analysis

### Side-by-side shape

**`Swift.RawRepresentable`** (stdlib):

```swift
public protocol RawRepresentable {
    associatedtype RawValue
    init?(rawValue: Self.RawValue)
    var rawValue: Self.RawValue { get }
}
```

**`Carrier<Underlying>`** (this package):

```swift
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    associatedtype Domain:     ~Copyable & ~Escapable
    associatedtype Underlying: ~Copyable & ~Escapable

    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
```

Superficial similarity — one associated type, one accessor, one init. Below is where it stops.

### Dimension 1 — Initializer fallibility

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Init form | `init?(rawValue: RawValue)` | `init(_ underlying: consuming Underlying)` |
| Failability | Yes — returns `nil` if the raw value is not a valid representation | No — always succeeds |
| Meaning | "Map a raw value back into its type, if it's a valid encoding" | "Construct a carrier from any underlying value" |
| Consumers | enum from `rawValue`, `OptionSet` raw-bit-pattern validation | Tagged wrapping any `RawValue`, Cardinal-shaped bare value round-tripping its underlying |

This is the largest single structural divergence. **RawRepresentable's failability is load-bearing** for its canonical use cases. Enum conformers implement it to reject raw-bit-patterns that don't map to any case (e.g., `enum Color: Int { case red = 0; case green = 1 }` — `Color(rawValue: 7)` returns `nil` because 7 is not a case). OptionSet conformers use it the same way for bitmask validation.

**Carrier is never-failing** because the Carrier abstraction is about wrapping, not about validating. `Tagged<UserTag, UInt64>(42)` cannot fail — any `UInt64` is a valid underlying for `Tagged<UserTag, UInt64>`. The phantom `UserTag` is informationally inert; no runtime check can reject a value based on it.

A non-failing `init(_:)` cannot satisfy `init?(rawValue:)` without always returning `.some` (which makes the fallibility cosmetic and confuses consumers). Going the other direction — making Carrier's init failable — would require every Carrier conformer to pretend construction can fail, which is false for all canonical conformers.

**Verdict**: the init forms are semantically incompatible. Neither can substitute for the other.

### Dimension 2 — Copyability and escapability

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Self | Implicitly Copyable | `~Copyable` suppression (admits both) |
| RawValue / Underlying | Implicitly Copyable | `~Copyable & ~Escapable` suppression (admits all four quadrants) |
| Stdlib runtime support | `RawRepresentable` is a pre-ownership protocol; integrations (Codable synthesis, OptionSet arithmetic) assume Copyable | Carrier is built on the post-SE-0427 / post-SE-0506 ~Copyable-aware Swift, with ownership annotations baked in |

RawRepresentable was introduced before Swift had ownership language features. Every stdlib facility that treats RawRepresentable specially (e.g., `Codable` auto-synthesis for RawRepresentable enums, `Hashable` derivation, `Comparable`) assumes Copyable `RawValue`. Retrofitting RawRepresentable to `~Copyable RawValue` would be an ABI break across the stdlib.

Carrier admits `~Copyable` and `~Escapable` across both Self and Underlying. This is the **reason Carrier exists** for the ecosystem's needs: `Tagged<Tag, MoveOnlyResource>` is a legitimate, load-bearing pattern (`Index<Element>` where `Element: ~Copyable`; `Tagged<Tag, Ownership.Inout<Base>>` storing an ~Escapable inout reference). RawRepresentable cannot express these shapes.

**Verdict**: Carrier covers design space that RawRepresentable cannot. A type with `~Copyable` or `~Escapable` Underlying can conform to Carrier but cannot conform to RawRepresentable.

### Dimension 3 — Ownership annotations

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Getter | `{ get }` — by-value read (implicitly copies) | `borrowing get` + `@_lifetime(borrow self)` — borrow-returning |
| Init parameter | `init?(rawValue: RawValue)` — by-value parameter | `init(_ underlying: consuming Underlying)` — consumes ownership |
| Expressiveness | Cannot describe borrow-only or consume-only contracts | Describes both |

The RawRepresentable getter signature `var rawValue: RawValue { get }` is a by-value read: consumers receive a fresh copy each access. For Copyable RawValue this is fine. For ~Copyable RawValue it is IMPOSSIBLE — a copy would be required to return, and ~Copyable forbids that. Similarly, the failable init takes its parameter by-value, which requires Copyable RawValue on the input side.

Carrier's `borrowing get` yields a borrow, not a copy. Works for both Copyable and ~Copyable Underlying. `consuming` init transfers ownership from caller to carrier, works for all quadrants. The `@_lifetime` annotations make the ~Escapable story coherent — the borrowed accessor's result has a lifetime tied to the carrier's storage.

**Verdict**: Carrier's ownership annotations are load-bearing for ~Copyable / ~Escapable conformance. RawRepresentable's lack of ownership annotations is a consequence of its pre-ownership era and cannot be retrofitted without ABI-breaking the stdlib.

### Dimension 4 — Associated type cardinality

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Associated types | 1 (`RawValue`) | 2 (`Domain`, `Underlying`) |
| Primary associated type | None | `Underlying` (SE-0346) |
| Phantom-domain story | Not expressible — the type has no way to carry a compile-time tag alongside the raw value | `Domain = Never` for trivial carriers, `Domain = Tag` for Tagged-family carriers; discriminates via the type system |

RawRepresentable has no phantom-tag dimension. `Color: RawRepresentable where RawValue == Int` has one dimension of variation — the raw value. It cannot discriminate "this is a `UserID`" from "this is an `OrderID`" when both wrap `Int`; that's why enums work (each case is a distinct type-level constant) but phantom-typed newtypes around the same primitive cannot use RawRepresentable to distinguish themselves in generic code.

Carrier's `Domain` associated type is the **compile-time tag dimension**. A generic function constrained on `some Carrier<Int>` can discriminate on `C.Domain` even when Underlying is identical — reflective diagnostics, cross-Carrier conversion, witness-based serialization all rely on this.

SE-0346's primary-associated-type spelling (`some Carrier<Underlying>`) also gives Carrier a cleaner API site shape than RawRepresentable could achieve even if retrofitted — existential `any RawRepresentable` erases `RawValue` entirely, whereas `some Carrier<Int>` preserves it at the constraint level.

**Verdict**: the second associated type (Domain) is what the carrier abstraction is for. RawRepresentable is definitionally a one-axis abstraction.

### Dimension 5 — Specialized stdlib integration

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| `Codable` auto-synthesis | Yes (for RawRepresentable enums whose RawValue is Codable) | No (no special stdlib integration) |
| `OptionSet` | RawRepresentable is the foundation of OptionSet | N/A |
| `Hashable`, `Equatable`, `Comparable` | Conformance derivation when RawValue conforms | Available on Tagged, not auto-derived from Carrier |
| `CaseIterable`, `@unknown default` in switch | Used together with RawRepresentable for enum exhaustiveness | N/A |

RawRepresentable has earned its place by being the substrate for stdlib features. Conforming to it gives enums / option sets code for free.

Carrier conformance gives ZERO stdlib-level benefit. The abstraction is ecosystem-internal — Carrier is visible to generic functions over carriers, but stdlib has no knowledge of it.

This is not a flaw in Carrier. It's a statement that the two protocols serve different tiers: RawRepresentable is stdlib-integrated; Carrier is ecosystem-integrated. Neither tier substitutes for the other.

**Verdict**: RawRepresentable sits at a level Carrier cannot reach. Carrier sits at a level RawRepresentable does not care about.

### Dimension 6 — Foundation dependence

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Foundation integration | Heavy — `RawRepresentable & Codable` is the canonical Foundation-era pattern for JSON-backed enums, NSCoding interop, etc. | None — carrier-primitives is Foundation-free per [PRIM-FOUND-001] |

Primitives-layer packages forbid Foundation imports. RawRepresentable is usable there (the protocol itself is stdlib), but the ecosystem around it (Codable, KeyDecodingStrategy, etc.) is not. The pattern a consumer expects from RawRepresentable — enum-with-String-rawValue, JSON encoding — is not what the primitives layer is for.

Carrier's world has no Foundation. It's designed for the primitives layer and composes cleanly with `~Copyable`, `~Escapable`, and the ecosystem's other primitives.

**Verdict**: RawRepresentable's broader value lives in places Carrier cannot go. Carrier fits a lane RawRepresentable wasn't designed for.

### Dimension 7 — Round-trip semantics

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| For Copyable | `self.rawValue` → `Self(rawValue:)` → `self` (when init returns `.some`) | `carrier.underlying` → `Carrier(carrier.underlying)` → equivalent carrier |
| For ~Copyable | N/A (unsupported) | Weakened — the init consumes; the "round-trip" is "borrow to inspect, consume to reconstruct" rather than "extract identical original" |
| Validation in the round-trip | RawRepresentable's round-trip is filtered by `init?` — some raw values round-trip to `nil` | Carrier's round-trip is total (never fails) |

This dimension is subtler than the init-fallibility dimension. RawRepresentable's round-trip property is "values that successfully round-trip are exactly the valid values of Self, and they round-trip identity-preservingly." Carrier's round-trip for Copyable Underlying is simpler: every underlying value round-trips.

For ~Copyable Underlying, Carrier weakens further — the "round-trip" is semantic rather than identity-preserving (see `capability-lift-pattern.md` §V5b and `self-projection-default-pattern.md` §"Round-trip (consume-then-reconstruct)"). RawRepresentable can't express any ~Copyable case, so the comparison doesn't arise.

**Verdict**: different guarantees. Consumers cannot freely interchange them. RawRepresentable's validating round-trip is not something Carrier can mimic without adding failability (which would break Carrier's canonical conformers).

### Dimension 8 — Tagged-forwarding and cross-type carrier relationships

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Free-Carrier relationship | None — each RawRepresentable conformance is ad-hoc | `Tagged<Tag, V>: Carrier` conforms automatically when `V: Carrier`, per the parametric extension pattern |
| Cross-type morphisms | None — there is no generic way to relate `T: RawRepresentable where RawValue == Int` to another `U: RawRepresentable where RawValue == Int` | `some Carrier<Int>` subsumes bare `Int` carriers AND any `Tagged<Tag, Int>` carrier for any Tag |
| Form-D generic algorithms | Not expressible — RawRepresentable's existential erases RawValue, and there's no parameterized-constraint spelling | Fully expressible — `func f<C: Carrier>(_ c: C) -> ...` works across all carrier shapes |

This is where the design space divergence shows up in API surface. A typical RawRepresentable use is a single enum or struct declaring its own conformance. There's no ecosystem story for "all types that represent an Int" — each RawRepresentable-Int conformer is its own island.

Carrier's design is precisely the ecosystem story. Every type that carries an Int — bare Cardinal, `Tagged<UserTag, Int>`, `Tagged<OrderTag, Int>` — joins the same family, visible at `some Carrier<Int>`. The `Domain` dimension is how they stay distinct while being compared or converted under a common abstraction.

**Verdict**: Carrier's design enables cross-type algorithms that RawRepresentable categorically cannot.

### Dimension 9 — Labeled vs positional parameters

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Init label | `init?(rawValue:)` — labeled | `init(_:)` — unlabeled |
| Rationale | Label disambiguates from other inits (validating, throwing, etc.) on the same type | Carrier's init IS THE canonical construction; no label needed |

Minor dimension but worth noting. RawRepresentable uses a labeled init because the type may have other inits; the label `rawValue:` anchors the semantics. Carrier uses an unlabeled init because it's the protocol's sole construction pathway.

Per `swift-tagged-primitives`'s [API-IMPL-009] convention for such primary constructors, an unlabeled `init(_:)` plus an `init(__unchecked:_:)` escape hatch (in Tagged's case) is the ecosystem pattern. Carrier-style unlabeled init aligns; RawRepresentable-style labeled init does not.

**Verdict**: minor, but consistent with the broader finding — the two protocols belong to different eras and conventions.

## Cross-cutting observations

### Why Tagged doesn't conform to RawRepresentable

`comparative-analysis-pointfree-swift-tagged.md` §3.1 records the Tagged-specific decision:

> `RawRepresentable` constrains `RawValue: Copyable` (it is not `~Copyable`-aware), which would block our noncopyable support.

Plus:

> It introduces `init?(rawValue:)` (failable) alongside the non-failable init, creating two construction paths with different semantics.

Both points generalize from Tagged to Carrier: the failability mismatch and the Copyable-only constraint are structural barriers to any Carrier conformer participating in RawRepresentable.

### Why not refine

A reasonable design proposal: `Carrier refines RawRepresentable` for Copyable conformers, with a separate non-refinement path for ~Copyable. Three problems:

1. **Init-fallibility still breaks the refinement**: Carrier's non-failable `init(_:)` cannot satisfy `init?(rawValue:)`. Even wrapping in `.some` everywhere creates a confusing dual construction path.
2. **Primary associated type**: Carrier's `<Underlying>` is primary; RawRepresentable has no primary associated type. Refining doesn't inherit primary-ness; the `some Carrier<X>` spelling would be lost if Carrier degraded to RawRepresentable-style API surface.
3. **Fragmentation**: if Carrier-for-Copyable refines RawRepresentable but Carrier-for-~Copyable does not, then `some Carrier<Int>` at a use site accepts both shapes — but only half of them are also `some RawRepresentable`. That split breaks the generic-dispatch story.

**Verdict**: refinement doesn't work structurally or ergonomically.

### Why not subsume

A second proposal: Carrier should make RawRepresentable unnecessary — deprecate RawRepresentable at the ecosystem level, require all conformers to use Carrier instead. Three problems:

1. **Stdlib integration**: RawRepresentable powers OptionSet, Codable auto-synthesis, enum rawValue access, and similar mechanisms that Carrier does not (and should not) replicate.
2. **Scope**: the ecosystem is not the consumer of all RawRepresentable uses — third-party code, Apple frameworks, Swift stdlib itself rely on it. Ecosystem packages can avoid RawRepresentable but cannot delete it.
3. **Failable-init use case**: enums with validating `init?(rawValue:)` is a legitimate pattern Carrier intentionally does not handle. The carrier abstraction isn't about validation.

**Verdict**: Carrier replaces RawRepresentable only for carriers; the rest of RawRepresentable's design space (validating wrappers, OptionSet-style bitmask types, Foundation-integrated enums) remains RawRepresentable's.

### Can a type be both?

Technically yes — nothing prevents a type from conforming to both Carrier and RawRepresentable. But:

- RawRepresentable's `init?(rawValue:)` must always return `.some` for Carrier's non-failing semantics to match, which defeats the point of RawRepresentable's failability.
- The two accessors (`rawValue` and `underlying`) would need to return the same value, doubling surface area.
- Consumers reading a double-conforming type are left to guess which protocol to target.

**Verdict**: dual conformance is a code smell. Pick one based on whether the type is a carrier (Carrier) or a raw-representable validating wrapper (RawRepresentable).

## Comparison summary

| Dimension | RawRepresentable | Carrier |
|-----------|------------------|---------|
| Init fallibility | Yes (`init?`) | No |
| ~Copyable / ~Escapable support | No | Yes (fundamental) |
| Ownership annotations | None | `consuming` init, `borrowing get`, `@_lifetime` |
| Associated type count | 1 (RawValue) | 2 (Domain, Underlying) |
| Primary associated type | No | Yes (Underlying) |
| Stdlib-integrated features | Codable, OptionSet, enum rawValue | None |
| Foundation era | Pre-ownership | Post-ownership |
| Round-trip shape | Failable, validating | Total for Copyable, weakened-but-total for ~Copyable |
| Cross-type generic algorithms | Not expressible | Fully expressible (Form D) |
| Init label convention | Labeled (`rawValue:`) | Unlabeled |
| Canonical use cases | Enum with raw type, OptionSet, Foundation-backed enums | Phantom-typed wrappers, Tagged family, Cardinal-shaped bare + tagged carriers |

## Outcome

**Status**: DECISION — Carrier and RawRepresentable are non-substitutable, non-refining protocols in different design spaces.

### Decisions

1. **Carrier does NOT refine RawRepresentable and does NOT get refined by it.** The init-fallibility mismatch, the ~Copyable/~Escapable support, and the dual associated-type cardinality are each structurally incompatible. Attempting either refinement direction would compromise the canonical conformers of one side or the other.

2. **Ecosystem types SHOULD NOT dual-conform.** If a type is phantom-typed-wrapper-shaped, conform to Carrier. If a type is validating-raw-value-shaped (enum, OptionSet, validated wrapper), conform to RawRepresentable. Do not conform to both — the two protocols' init semantics conflict.

3. **The ecosystem's convention that Tagged does NOT conform to RawRepresentable** (per `comparative-analysis-pointfree-swift-tagged.md` §3.1) extends to every Carrier conformer. Cardinal, Ordinal, Hash.Value, and Tagged all stay non-RawRepresentable; they conform to Carrier instead when they adopt the super-protocol.

4. **Consumer API surfaces that want "wrapper over X" should take `some Carrier<X>`, not `some RawRepresentable where RawValue == X`.** The latter excludes ~Copyable wrappers, fails for failable-init cases that aren't relevant, and loses the Domain discrimination.

5. **RawRepresentable remains correct for its own use cases.** Validating enums (`init?(rawValue:)` that rejects invalid bit patterns), OptionSet conformers, Foundation-integrated types — all continue to use RawRepresentable. Nothing about Carrier suggests the ecosystem should discourage RawRepresentable outside the carrier family.

### What this document does NOT do

- Recommend deprecating RawRepresentable at any scope.
- Propose a refinement hierarchy that unifies Carrier with RawRepresentable.
- Prescribe that every enum or validating wrapper should migrate to Carrier — that would be a category error. Only phantom-typed wrappers (the carrier family) should use Carrier.
- Address whether Carrier should interop with third-party RawRepresentable-based libraries (e.g., via an adapter type). That's a future integration question; not in scope here.

## Constraints

- **[PRIM-FOUND-001]** — Carrier is Foundation-free. Any RawRepresentable integration that would require Foundation is out of scope for swift-carrier-primitives.
- **Swift stdlib ABI** — RawRepresentable's shape is frozen. Any retrofit (making RawValue `~Copyable`, changing init to non-failable) is not on the table.
- **SE-0346** — Carrier's primary-associated-type shape `Carrier<Underlying>` requires SE-0346; enabled in Swift 6.3+. RawRepresentable does not use this feature.
- **Swift 6.3.1 experimental features** — Carrier's `~Copyable` / `~Escapable` suppression requires `SuppressedAssociatedTypes`. This is not a limitation of RawRepresentable; it's what Carrier needs to cover the four quadrants.

## References

### Primary sources

- `Sources/Carrier Primitives/Carrier.swift` — the Carrier protocol declaration.
- Swift stdlib — `Swift.RawRepresentable` protocol declaration. (No inline reference here; the protocol is stable and consumed from stdlib.)

### Related research

- `swift-tagged-primitives/Research/comparative-analysis-pointfree-swift-tagged.md` (DECISION, 2026-02-26) §3.1 — type-level rationale for Tagged not conforming to RawRepresentable. The foundational decision this super-protocol analysis builds on.
- `swift-carrier-primitives/Research/capability-lift-pattern.md` (RECOMMENDATION, v1.1.0) — §"Tagged as the canonical Carrier" establishes that Tagged is the free/canonical implementation of Carrier. The RawRepresentable comparison inherits Tagged's rejection.
- `swift-ownership-primitives/Research/self-projection-default-pattern.md` (RECOMMENDATION, 2026-04-24) — the orthogonal meta-pattern for self-projecting capability protocols (Borrow family). Complements Carrier in the cross-ecosystem taxonomy.

### Language references

- **SE-0155** — `RawRepresentable` stdlib declaration.
- **SE-0346** — Lightweight same-type requirements for primary associated types (enables `some Carrier<Underlying>`).
- **SE-0427** — Noncopyable generics (enables `~Copyable` on generic parameters).
- **SE-0506** — Noncopyable associated types (relevant to Carrier's ~Copyable-aware associated types).
- **Swift 6.3.1 experimental features** — `Lifetimes`, `SuppressedAssociatedTypes`.

### Convention sources

- **[PRIM-FOUND-001]** — Foundation-free primitives layer.
- **[API-IMPL-009]** — Hoisted protocol with nested typealias (relevant to Carrier's non-namespaced shape vs RawRepresentable's module-scope shape).
- **[RES-020]** — Research tier rules (this doc is Tier 2).
- **[RES-010]** — Comparative analysis template.
