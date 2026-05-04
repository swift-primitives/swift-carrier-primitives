# Understanding Carriers

@Metadata {
    @TitleHeading("Carrier Primitives")
}

The carrier abstraction, its relationship to phantom-typed wrappers, and where it fits against other meta-patterns in the primitives ecosystem.

## What is a carrier?

A `Carrier` is a type that exposes an `Underlying` value through a borrowing accessor and constructs from an underlying via a consuming init. It's the generalization of "wrapper type" from the four concrete instances that appear in the primitives layer:

- A bare value type that is its own underlying (`Cardinal.underlying == self`).
- A Tagged wrapper around a value (`Tagged<User, Int>.underlying == storedInt`).
- A scoped borrowed reference to a value (`Ownership.Inout<Base>` or similar).
- Combinations of these.

The common shape is: a value accessor, a construction path, and an optional phantom-tag discriminator (`Domain`). Everything else — the specific storage, the specific semantic role, the specific per-type operations — lives in each conformer.

## Domain and Underlying — why two associated types?

`Underlying` is the wrapped value type. `Domain` is a phantom tag discriminating otherwise-indistinguishable carriers of the same Underlying.

Without `Domain`, `Tagged<User, Int>` and `Tagged<Order, Int>` would look identical to generic code — both conform to `some Carrier.`Protocol`<Int>`, both expose `underlying: Int`, both construct the same way. The Tag information would be lost at the generic dispatch level.

With `Domain`, generic code can reflect on `C.Domain` to distinguish the tags at the type level:

```swift
func diagnose<C: Carrier>(_ c: C) -> String {
    "Error in Carrier<\(C.Underlying.self)> from domain \(C.Domain.self)"
}

diagnose(Tagged<User, Int>(42))   // "... Domain User"
diagnose(Tagged<Order, Int>(42))  // "... Domain Order"
```

The runtime value (42) is the same, but the compile-time metadata differs. Carrier preserves that distinction in the generic setting.

For bare types that don't need phantom discrimination (the carrier is the underlying), `Domain` defaults to `Never`. Conformers skip the `typealias Domain = ...` line and get the trivial semantics for free.

## The four-quadrant grid

Carrier admits four shapes via independent `~Copyable` / `~Escapable` suppression on both `Self` and `Underlying`:

### Quadrant 1 — Copyable & Escapable

The everyday case. `Underlying` is a plain value type (`Int`, `Double`, a struct). The carrier itself can be copied and passed anywhere. `@_lifetime` annotations are omitted on the conformer's getter/init (Swift rejects them on Escapable results).

### Quadrant 2 — `~Copyable` & Escapable

`Underlying` is a move-only resource (file descriptor, unique handle, allocation). The carrier is also `~Copyable` — copying the carrier would copy the underlying, which is forbidden. The getter uses `_read { yield ... }` to provide borrowing access without consuming the stored value. `@_lifetime` annotations are still omitted (Escapable Underlying rejects them).

### Quadrant 3 — Copyable & `~Escapable`

`Underlying` is a scoped reference or view (borrowed span, lifetime-bounded pointer). The carrier is `~Escapable` because its lifetime is tied to the underlying's scope. Both getter and init require `@_lifetime` annotations because the returned / stored value has a scoped lifetime.

### Quadrant 4 — `~Copyable` & `~Escapable`

Both suppressions apply. The most restrictive shape; typical for move-only scoped references like a `~Copyable & ~Escapable` mutable view. Getter and init both require `@_lifetime` annotations.

## Round-trip weakening for `~Copyable`

For `Copyable` Underlying, `carrier.underlying` returns a copy, and `C(carrier.underlying)` constructs a new carrier with an identical underlying. The round-trip is total and identity-preserving.

For `~Copyable` Underlying, `carrier.underlying` returns a borrow — a scoped reference that cannot be consumed. The borrow cannot be fed back into `C(_:)` because the init requires `consuming`, not borrowing. The round-trip becomes "inspect the underlying via the borrow, reconstruct with a fresh consumed value" rather than "extract identical original."

This is a semantic weakening, not a bug. The alternative — splitting Carrier into `CopyableCarrier` and `NoncopyCarrier` siblings — was considered and rejected. See <doc:Round-trip-Semantics> for the full discussion. The unified protocol is simpler, and consumers that need the identity-preserving round-trip stick to `Copyable` Underlying conformers.

## Relationship to capability-lift per-type protocols

Before Carrier, each ecosystem value type (Cardinal, Ordinal, Hash.Value) declared its own capability protocol (`Cardinal.\`Protocol\``, `Ordinal.\`Protocol\``, `Hash.\`Protocol\``) following the same recipe: bare type + Tagged forwarding. Those protocols still exist and remain the primary API shape for domain-specific operations — `func align<C: Cardinal.\`Protocol\`>(_ c: C)` is the right form for Cardinal-specific arithmetic.

Carrier is the super-abstraction under which those per-type protocols compose. When a package declares `extension V: Carrier.`Protocol` where ...`, it opts into the family without giving up its per-type protocol. API sites can choose:

- `some Cardinal.\`Protocol\`` — domain-axis: matches bare `Cardinal` AND `Tagged<Tag, Cardinal>` AND any other Cardinal-domain-conforming type, regardless of wrapping depth. Use this for "any Cardinal-carrying value" APIs.
- `some Carrier.`Protocol`<Cardinal>` — depth-axis: matches types whose `Carrier.Underlying` is exactly `Cardinal` (i.e., `Tagged<Tag, Cardinal>`). Does NOT match bare `Cardinal` post-cardinal-cascade-drop, where `Cardinal.Underlying == UInt`. Use only when the immediate-wrap depth is load-bearing.
- `some Carrier` — fully generic: any carrier at all (cross-Carrier algorithms).

The three are NOT equivalent — they target different population sets.
`Cardinal.\`Protocol\`` is typically the right choice; `Carrier<Cardinal>`
is correct only when the immediate wrapping depth must equal Cardinal.

## Relationship to self-projection-default

The self-projection-default pattern (`Ownership.Borrow.\`Protocol\`` and its family, characterized in `swift-ownership-primitives/Research/self-projection-default-pattern.md`) is ORTHOGONAL to Carrier. Self-projection addresses an `associatedtype defaults to N<Self>` shape — a borrow or projection derived from Self. Carrier addresses a carrier relationship where the carrier wraps a distinct Underlying.

A type may participate in either, both, or neither:

- **Carrier only**: `Cardinal` — carries itself; has no Self-projection type.
- **Self-projection only**: most `Ownership.Borrow.\`Protocol\`` conformers — have a borrowed view but aren't "carriers" of another value.
- **Both**: a hypothetical future type that carries an Underlying AND projects a borrowed form.
- **Neither**: `Property<Tag, Base>` — verb-namespace wrapper; Group B per the taxonomy, categorically unsuited to Carrier and not Self-projecting either.

## Which Group — A or B?

The Tagged / Property split from `swift-property-primitives/Research/property-tagged-semantic-roles.md` partitions phantom-typed wrappers into:

- **Group A — domain-identity phantom wrappers** (Tagged). The tag identifies what kind of value is wrapped. `retag<NewDomain>` is a meaningful cross-fiber morphism. Extensions are per-domain. **Carrier is designed for Group A.**
- **Group B — verb-namespace phantom wrappers** (Property). The tag selects which extension methods apply. Cross-fiber morphisms don't exist (retagging `Push` to `Pop` would be semantically nonsensical). **Carrier does not fit Group B.**

`Property<Tag, Base>` explicitly does NOT conform to Carrier. The verb-namespace's sealed-fiber structure is fundamentally incompatible with Carrier's round-trip-and-discriminate-by-Domain shape. See the research docs for the categorical asymmetry argument.

## When to reach for Carrier

If you're a downstream package and asking "should I use Carrier?":

| Situation | Answer |
|-----------|--------|
| You're writing a phantom-typed wrapper around an Underlying value | Probably yes — conform in your package. |
| You want to write a function accepting any carrier of a specific Underlying | Yes — use `some Carrier.`Protocol`<X>`. |
| You want to write a function accepting any carrier of any type | Yes — use `some Carrier & ~Copyable & ~Escapable` (Form D). |
| You want diagnostics that reflect on the phantom Domain | Yes — `C.Domain.self` gives it to you. |
| You're writing a type with validating init (like an enum raw-value case) | No — use `RawRepresentable` instead. See <doc:Carrier-vs-RawRepresentable>. |
| You're writing a verb-namespace wrapper (Property-shape) | No — Group B is categorically blocked from Carrier. |

## See Also

- ``Carrier``
