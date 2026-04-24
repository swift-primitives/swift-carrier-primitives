# SLI — Span family (`Span`, `MutableSpan`, `RawSpan`, `MutableRawSpan`): Skip (strongest could-be-done case)

<!--
---
version: 1.0.0
last_updated: 2026-04-24
status: DECISION
tier: 1
scope: swift-carrier-primitives SLI target
---
-->

## Context

Swift 6 introduces the span family (SE-0447 `Span<Element>`, SE-0467 `MutableSpan<Element>`, plus `RawSpan` / `MutableRawSpan`) as `~Escapable` contiguous-memory views. Copyable, `~Escapable`. These fit Carrier's Q3 quadrant (Copyable × `~Escapable`). Should any conform to `Carrier`?

## Analysis

### Structural match

`Span<Element>` is Copyable and `~Escapable`. The generic self-carrier form is viable:

```swift
extension Span: Carrier {
    public typealias Underlying = Span<Element>
    // The default extension provides getter + init, BUT the default
    // is written for Escapable types (omits @_lifetime annotations).
    // For ~Escapable Self, the default's `_read { yield self }` may or
    // may not pass the @_lifetime(borrow self) requirement on the
    // protocol; needs verification.
}
```

### Semantic fit

Span IS a value carrier in a defensible sense — `Span<Int>` carries a `Span<Int>` (itself). The `~Escapable` shape matches Carrier's Q3 quadrant structurally. Form-D generic algorithms (`describe<C: Carrier & ~Copyable & ~Escapable>(_ c: borrowing C)`) would work on Span.

### Why skip

1. **Verification cost.** The trivial-self-carrier default extension uses `_read { yield self }` without `@_lifetime(borrow self)`. Whether this satisfies the protocol's `@_lifetime(borrow self) borrowing get` requirement for `~Escapable` Self is unverified; it might compile but produce wrong lifetime semantics at consumer call sites. Would need bespoke conformance with explicit `@_lifetime` annotations per span type — not a one-liner.

2. **Generic type wrinkle.** Span takes a `Pointee: ~Copyable & ~Escapable` parameter (analogous to Array's Element). Parametric Carrier shapes ("Span of a Carrier Pointee") have the same Array-family complications (see `sli-array.md`).

3. **Conformance would require explicit bodies.** The trivial-self-carrier default likely can't cover Span safely; each Span variant would need its own extension with `@_lifetime` annotations. Four types × explicit bodies is higher effort than the Copyable SLI conformances (one-liner each).

4. **Single-conformance lock.** Shipping `Span<Element>: Carrier` centrally forbids consumer-declared parametric shapes for Span, which is especially costly for a type as new and evolving as Span.

### Could-it-be-done verdict

| Form | Viable? | Cost |
|------|---------|------|
| Self-carrier with default extension | Unverified; may fail `@_lifetime` requirement | Needs testing |
| Self-carrier with explicit `@_lifetime` | Yes | 4 explicit bodies, not one-liners |
| Parametric (Element-unwrap) | Yes, non-trivially | Array-family complications |

## Outcome

**Status**: DECISION — skipped from 0.1.0 SLI.

**Rationale**: Span fits Carrier's Q3 quadrant structurally and would be the first SLI conformer to exercise `~Escapable` Self at stdlib integration scope. But the trivial-self-carrier default may not handle `@_lifetime` correctly; each Span variant would need a bespoke conformance; and Span is too new to centralize a single parametric shape at 0.1.0 FINAL.

This is the SLI candidate with the strongest could-be-done case. Post-0.1.0 — if a consumer surfaces concrete need for `some Carrier<Span<UInt8>>` APIs — they can declare their own conformance, potentially shipping it in their package.

## References

- Swift stdlib `Span<Element>` (SE-0447), `MutableSpan<Element>` (SE-0467), `RawSpan`, `MutableRawSpan`.
- `Research/capability-lift-pattern.md` §V5b, V5c — `~Copyable` and `~Escapable` quadrant considerations.
- `Carrier+Trivial.swift` — the default extension whose lifetime semantics would need per-span verification.
