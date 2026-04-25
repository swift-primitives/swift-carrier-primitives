# `@dynamicMemberLookup` on Carrier — Decision

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

A reasonable ergonomic question: should `Carrier` be marked `@dynamicMemberLookup` so that consumers can write `wrapper.someProperty` instead of `wrapper.underlying.someProperty`? This is the pattern point-free's `swift-tagged` adopted, and stdlib precedents (`KeyPath`-based dynamic lookup on existential containers) show the affordance is well-understood.

The question is more fragile than it appears because Carrier deliberately spans four Copyable × Escapable quadrants of `Underlying`. An ergonomic that works only in some quadrants creates asymmetric API surface, which is worse than uniform absence of the affordance.

This decision is grounded by empirical results in `Experiments/dynamic-member-lookup-quadrants/` (V1 CONFIRMED, V2/V3 REFUTED, Q4 REFUTED by transitivity).

## Analysis

### Empirical findings

The experiment annotated `Carrier` with `@dynamicMemberLookup` and provided a default subscript on a protocol extension:

```swift
@dynamicMemberLookup
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    associatedtype Underlying: ~Copyable & ~Escapable
    var underlying: Underlying { ... }
    init(_ underlying: consuming Underlying)
}

extension Carrier {
    public subscript<T>(dynamicMember keyPath: KeyPath<Underlying, T>) -> T {
        underlying[keyPath: keyPath]
    }
}
```

| Quadrant | Self | Underlying | Member-access expression | Verdict |
|----------|------|------------|--------------------------|---------|
| Q1 | Copyable & Escapable | Copyable & Escapable | `id.description` | CONFIRMED — resolves through dynamic lookup |
| Q2 | ~Copyable | ~Copyable | `wrapper.raw` | REFUTED — diagnostic: `requires that 'UniqueWrapper' conform to 'Copyable'` and `requires that 'UniqueWrapper.Underlying' conform to 'Copyable'` |
| Q3 | ~Escapable | ~Escapable | `wrapper.raw` | REFUTED — diagnostic: `requires that 'ScopedWrapper' conform to 'Escapable'` and `requires that 'ScopedWrapper.Underlying' conform to 'Escapable'` |
| Q4 | ~Copyable & ~Escapable | ~Copyable & ~Escapable | n/a | REFUTED by transitivity — both Q2 and Q3 mechanisms apply |

Two sub-findings from V1:

- **`@dynamicMemberLookup` on a protocol declaration is accepted in Swift 6.3 and propagates to conformers.** Q1's `UserID` carries no `@dynamicMemberLookup` annotation of its own, yet the dot-syntax affordance is available at use sites — protocol-level annotation is sufficient.
- **The default subscript on a protocol extension materializes only when `Self: Copyable & Escapable` and `Self.Underlying: Copyable & Escapable`.** These constraints are implicit in the `KeyPath<Root, Value>` type's own constraints; they cannot be relaxed in Swift 6.3 without language-level changes to KeyPath.

### Implications

The empirical result rules out a clean adoption shape. If we add `@dynamicMemberLookup` to Carrier:

1. **Q1 conformers get the ergonomic.** Both trivial self-carriers (`Int: Carrier where Underlying == Int`) and tagged carriers with Copyable Underlying (`User.ID = Tagged<User, Int>`) gain the dot-syntax affordance.

2. **Q2/Q3/Q4 conformers silently do not.** A consumer reaching for `someUniqueCarrier.raw` or `someSpanCarrier.count` gets the Carrier protocol's diagnostic, not the affordance they expected. The diagnostic mentions the implicit `Copyable` / `Escapable` requirement that they did not write — it is not obvious from the conformer's declaration site that the affordance is unavailable.

3. **Generic algorithms `func f<C: Carrier>(_ c: C)` cannot rely on dot-syntax for Underlying members in any case** — the protocol's surface defines what's reachable through the existential, and dynamic member lookup is a concrete-type-only affordance. So adding `@dynamicMemberLookup` doesn't help generic dispatch; it only helps concrete sites.

### Conceptual fit

Carrier's purpose is to keep phantom-typed wrappers *distinct* from their underlying — `User.ID` is not an `Int`, even when both have the same in-memory shape. Dynamic member lookup forwards member access from the wrapper to the underlying, partly undoing that distinction. The wrapper's API surface becomes "everything Underlying exposes plus what the wrapper itself adds," which is exactly what the type-system separation was preventing.

This is the core argument from `Research/carrier-vs-rawrepresentable-comparative-analysis.md` (DECISION, 2026-04-24): RawRepresentable and Carrier occupy non-substitutable design spaces. RawRepresentable's `rawValue` projection is explicit ceremony; consumers spell out the boundary crossing. The Carrier ecosystem inherits that stance — `wrapper.underlying.foo` is intentionally heavier than `wrapper.foo` because the dot signals "I am crossing from the carrier's domain into the underlying's."

`swift-tagged-primitives` design notes (`comparative-analysis-pointfree-swift-tagged.md`) record the deliberate rejection of point-free Tagged's tighter coupling to RawValue. Adding `@dynamicMemberLookup` at the Carrier-protocol level partially walks that decision back for the Q1 subset of conformers, while inconsistently providing nothing for Q2/Q3/Q4.

### Reversibility

| Action | Reversibility |
|--------|---------------|
| Add `@dynamicMemberLookup` to Carrier later | Non-breaking (new lookup paths become available) |
| Remove `@dynamicMemberLookup` from Carrier later | Breaking (existing `wrapper.foo` call sites stop compiling) |

This is a one-way door. The conservative default is "don't add unless concrete demand surfaces."

### Consumer-side escape hatch

A consumer who specifically wants dynamic member lookup for their own Carrier-conforming type can apply `@dynamicMemberLookup` to the conforming type and provide a subscript:

```swift
@dynamicMemberLookup
struct UserID: Carrier {
    typealias Underlying = User
    var user: User
    var underlying: User { user }
    init(_ underlying: consuming User) { self.user = underlying }

    subscript<T>(dynamicMember keyPath: KeyPath<User, T>) -> T {
        user[keyPath: keyPath]
    }
}
```

This scopes the choice locally to types where the consumer accepts the trade-off, without imposing it on all Carrier conformers.

## Outcome

**Status**: DECISION — do not add `@dynamicMemberLookup` to the `Carrier` protocol or its default extensions.

**Rationale**:

1. **Asymmetry across quadrants.** The KeyPath subscript materializes only for Q1; Q2/Q3/Q4 silently lack the affordance. Asymmetric ergonomics are worse than uniform absence — a consumer expects `wrapper.foo` to either always work or never work.
2. **Conceptual fit.** Carrier exists to keep phantom wrappers distinct from underlying. Forwarding member access partially undoes that separation, in tension with the deliberate stance in `Research/carrier-vs-rawrepresentable-comparative-analysis.md`.
3. **One-way door.** Adding the affordance later is non-breaking; removing it is breaking. Conservative default.
4. **Consumer escape hatch.** Specific Q1 consumers can apply `@dynamicMemberLookup` to their own Carrier-conforming type — scoping the choice locally without imposing it ecosystem-wide.

**Revisit triggers**:

- Swift relaxes `KeyPath`'s `Root: Copyable & Escapable` constraint such that `KeyPath<~Copyable Root, T>` and `KeyPath<~Escapable Root, T>` typecheck. If the asymmetry is removed, the conceptual-fit argument becomes the sole remaining one against and is worth revisiting under concrete consumer demand.
- A pattern emerges where multiple ecosystem packages all apply `@dynamicMemberLookup` to their Q1 Carrier conformers — at that point the consumer-side escape hatch has become repetitive boilerplate and centralization may be worth the conceptual-fit cost.

Neither trigger is active as of 2026-04-25.

## References

- `Experiments/dynamic-member-lookup-quadrants/` — V1 CONFIRMED, V2 REFUTED, V3 REFUTED, Q4 REFUTED by transitivity (2026-04-25)
- `Research/carrier-vs-rawrepresentable-comparative-analysis.md` — DECISION (2026-04-24): Carrier and RawRepresentable occupy non-substitutable design spaces; explicit projection is the shared stance
- `swift-tagged-primitives/Research/comparative-analysis-pointfree-swift-tagged.md` — point-free Tagged's `@dynamicMemberLookup` adoption and the ecosystem's deliberate divergence from it
- `Sources/Carrier Primitives/Carrier.swift` — protocol declaration (no `@dynamicMemberLookup`, post-decision)
- SE-0252 — Key Path Member Lookup (the language feature under evaluation)
