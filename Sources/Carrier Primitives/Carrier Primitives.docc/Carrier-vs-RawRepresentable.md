# Carrier vs RawRepresentable

@Metadata {
    @TitleHeading("Carrier Primitives")
}

A decision tree for picking between `Carrier.`Protocol`<Underlying>` and Swift stdlib's `RawRepresentable`. The short version: the two protocols occupy non-overlapping design spaces; neither subsumes the other.

## Overview

`Carrier.`Protocol`<Underlying>` and `RawRepresentable` look structurally similar — one associated type, one accessor, one init. The superficial resemblance invites the question "why not just use `RawRepresentable`?" This article answers it with a decision tree.

## Quick decision tree

| Your situation | Use |
|----------------|-----|
| You're wrapping an `Int`/`String`/similar with a phantom type tag (e.g., `User.ID`, `Order.ID`) | `Carrier` |
| Your type is `~Copyable` or `~Escapable`, or wraps one | `Carrier` (RawRepresentable cannot express these) |
| You're writing a generic function accepting any carrier of `Int` | `Carrier` (use `some Carrier.`Protocol`<Int>`) |
| You're writing an enum with validating `init?(rawValue:)` (some raw values reject as `nil`) | `RawRepresentable` |
| You're writing an `OptionSet` | `RawRepresentable` (OptionSet refines it) |
| You want Foundation's Codable auto-synthesis for a raw-valued enum | `RawRepresentable` |
| You're writing a validating wrapper (e.g., `struct NonEmptyString`) | `RawRepresentable` — Carrier cannot express fallibility |

## Five load-bearing differences

### 1. Init fallibility

| | `RawRepresentable` | `Carrier` |
|---|---|---|
| Init | `init?(rawValue:)` — may fail | `init(_:)` — always succeeds |
| Purpose | Reject invalid bit patterns | Wrap any underlying value |

`Color(rawValue: 7)` returns `nil` when 7 isn't a case. `Tagged<User, UInt64>(42)` cannot fail — any `UInt64` is a valid wrapped value. Carrier intentionally does not carry validation semantics.

### 2. Copyability and escapability support

| | `RawRepresentable` | `Carrier` |
|---|---|---|
| `Self` | Implicit Copyable | Admits `~Copyable` suppression |
| `RawValue` / `Underlying` | Implicit Copyable & Escapable | Admits `~Copyable & ~Escapable` suppression |

`RawRepresentable` predates ownership language features. Its stdlib integrations (Codable synthesis, OptionSet arithmetic, `Hashable`/`Comparable` derivation) all assume `Copyable RawValue`. Retrofitting `~Copyable` is an ABI break.

`Carrier` was designed post-SE-0427 / SE-0506. `Tagged<User, FileHandle>` with `FileHandle: ~Copyable` conforms cleanly; `RawRepresentable` cannot express this.

### 3. Ownership annotations

| | `RawRepresentable` | `Carrier` |
|---|---|---|
| Getter | `{ get }` — by-value read | `borrowing get` + `@_lifetime(borrow self)` |
| Init | By-value parameter | `consuming` parameter with `@_lifetime(copy underlying)` |

`Carrier`'s annotations are load-bearing for `~Copyable` / `~Escapable` support. `RawRepresentable`'s absence of annotations is a consequence of its pre-ownership era.

### 4. Two associated types (phantom-tag dimension)

| | `RawRepresentable` | `Carrier` |
|---|---|---|
| Associated types | 1 (`RawValue`) | 2 (`Domain` + `Underlying`) |
| Phantom discrimination | Not expressible | `Domain` associated type |
| Primary associated type | No | `Underlying` (SE-0346) |

`User.ID` and `Order.ID` — both wrapping `UInt64` with phantom `Domain` set to their enclosing type — are distinguishable under `Carrier` (different `Domain`s) but indistinguishable under `RawRepresentable` (same `RawValue`). Generic functions reflecting on `C.Domain` distinguish them at the type level.

### 5. Stdlib and Foundation integration

| | `RawRepresentable` | `Carrier` |
|---|---|---|
| `Codable` auto-synthesis for raw-valued enums | Yes | No |
| `OptionSet` foundation | Yes | N/A |
| Enum `.rawValue` / `@unknown default` | Yes | N/A |
| Foundation integration | Heavy (NSCoding, Codable) | None — Carrier is `[PRIM-FOUND-001]`-compliant |

`RawRepresentable` is the substrate for stdlib features. `Carrier` sits at the ecosystem level below stdlib integration — different tier, different job.

## What happens if you conform to both?

It's technically possible but semantically a code smell:

- `RawRepresentable`'s `init?(rawValue:)` must always return `.some` to match `Carrier`'s non-failing semantics, which defeats the validation purpose.
- Two accessors (`rawValue` and `underlying`) must return the same value, doubling API surface.
- Consumers reading the double-conformance are left guessing which protocol to target.

Recommendation: pick one per type based on whether the type is a *carrier* (Carrier) or a *validating wrapper* (RawRepresentable).

## Should `Carrier` refine or subsume `RawRepresentable`?

No and no. Refinement fails on the init-fallibility mismatch: `Carrier`'s non-failing init cannot satisfy `init?(rawValue:)`. Subsumption would delete `RawRepresentable`'s stdlib integrations without replacement. The two protocols coexist in different design spaces.

## See Also

- ``Carrier``
- <doc:Understanding-Carriers>
- <doc:Conformance-Recipes>
