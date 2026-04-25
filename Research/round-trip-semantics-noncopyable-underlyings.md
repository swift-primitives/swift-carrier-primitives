# Round-trip semantics for `~Copyable` Underlyings

<!--
---
version: 1.0.0
last_updated: 2026-04-24
status: DECISION
tier: 2
scope: package-specific
---
-->

## Context

`Carrier<Underlying>` exposes `underlying` as a borrow and accepts `consuming Underlying` for construction:

```swift
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
```

A naïve reading of this shape is: "given a `Carrier`, you can read its `underlying` and reconstruct an equivalent `Carrier` from what you read." For **Copyable** Underlyings, that reading is correct. For **~Copyable** Underlyings it is not — and the gap is load-bearing enough to document explicitly.

## The semantic property

The getter yields a **borrow** of the `Underlying`. The init consumes an **owned** `Underlying`. A borrow is not owned; you cannot pass it to a `consuming` parameter.

For Copyable Underlying this asymmetry is invisible because any borrowed value can be copied into a fresh owned one. For `~Copyable` Underlying there is no copy — so you cannot move from `carrier.underlying` (a borrow) into `Carrier.init(_:)` (a consume) without owning a *separate* `Underlying` instance.

## What works and what doesn't

| Scenario | Copyable Underlying | `~Copyable` Underlying |
|----------|---------------------|------------------------|
| Borrow `underlying`, inspect, build new carrier from a copy | ✓ works (copy is implicit) | ✗ cannot compile (no copy available) |
| Consume the carrier to extract owned `underlying`, pass to new `Carrier.init(_:)` | ✓ works (but destroys the original) | ✓ works (and destroys the original) |
| Own a *separate* `Underlying`, pass to `Carrier.init(_:)` | ✓ works | ✓ works (caller supplies a fresh owned instance) |
| Round-trip `self.underlying → Self.init(self.underlying)` with `self` still valid | ✓ works | ✗ impossible by design |

The last row is the one that surprises readers. It's the intended behavior — the whole point of `~Copyable` is that a value has exactly one owner — but the symmetry of the protocol's shape invites the mistake.

## Why this is not a bug

- **Linear-type discipline**: `~Copyable` types are linear. Round-trip-with-original-preserved is a Copyable property, not a universal Carrier property.
- **Ownership transfer**: `consuming init` transferring ownership is correct. An alternative `init(borrowing:)` would require the carrier to copy the borrowed value, which `~Copyable` forbids.
- **`_read { yield self }` in the trivial-self default**: the default extension uses `_read` precisely because `borrowing get { self }` would require `Self: Copyable`. The protocol was designed with `~Copyable` Self in mind; the round-trip asymmetry is not an oversight.

## The correct pattern for `~Copyable` Underlying

Consumers that need to "change the carrier" for a `~Copyable` Underlying have two options:

The worked examples below use the Q2 recipe from `Sources/.../Conformance-Recipes.md` — `File.Handle` is the carrier, `File.Descriptor` is the `~Copyable` underlying.

### Option A — Consume and reconstruct

```swift
var handle: File.Handle = ...
let descriptor = consume handle               // destroys handle; takes ownership of its descriptor
// ... do something with descriptor, perhaps producing a new owned value ...
let rebuilt = File.Handle(descriptor)         // consumes descriptor; produces new carrier
```

This is the *canonical* ~Copyable pattern: one carrier in, one carrier out, the path between them passing through an owned value.

### Option B — Supply a fresh Underlying from elsewhere

```swift
let freshDescriptor = File.Descriptor(raw: openedByCaller)   // new owned descriptor
let handle = File.Handle(freshDescriptor)                    // consumes it
```

Here `freshDescriptor` is not `handle.underlying` from any pre-existing carrier — it's a separately-owned value. The `consuming init` works fine because ownership transfers cleanly.

### What does NOT work

```swift
// COMPILE ERROR for File.Handle with ~Copyable File.Descriptor:
let first: File.Handle = ...
let second = File.Handle(first.underlying)    // ✗ can't consume a borrow
```

`first.underlying` is a borrowed `File.Descriptor` by the protocol's `borrowing get` requirement. `File.Handle.init(_:)` takes `consuming File.Descriptor`. You cannot pass a borrow where a consume is expected.

## Relationship to the trivial-self default

The trivial-self-carrier default (`extension Carrier where Underlying == Self`) uses `_read { yield self }` for the getter precisely because a Copyable-only `borrowing get { self }` would exclude `~Copyable` Self. For `Self: ~Copyable & Underlying == Self`, the round-trip semantics collapse further:

```swift
// Even more restrictive — Self IS Underlying, so "round-trip" means
// destroying the carrier to yield its own self.
var resource: Some.Resource = ...         // Some.Resource: ~Copyable, Carrier, Underlying == Self
let extracted = consume resource          // resource and its underlying are now owned by extracted
// No distinction between the carrier and its underlying anymore.
```

This is fine — ~Copyable self-carriers are rare, and when they exist the distinction between "the carrier" and "its underlying" is vacuous anyway.

## Implications for generic algorithms

A generic function over `some Carrier<Underlying>` that needs to "rebuild" the carrier from its underlying must decide:

1. **Is this operation always safe?** Only if Underlying is `Copyable`. Constrain on `where Underlying: Copyable` and the round-trip pattern works cleanly.
2. **Does the algorithm consume the carrier?** If yes, ~Copyable works fine — the algorithm owns the carrier and can extract the underlying.
3. **Is the algorithm read-only?** Then don't rebuild. Use `borrowing` consistently and let the caller manage carrier construction.

Most Carrier-consuming algorithms fall into category 3 (read-only) — they observe the underlying and return a fresh value without rebuilding any carrier. The round-trip asymmetry only matters for algorithms that want to *transform* a carrier, and for those, either a Copyable constraint or a consuming signature is required.

## What this means for the API surface

The protocol's shape is correct. The confusion is consumer-side: documentation needs to state the round-trip asymmetry explicitly rather than leaving it implicit in the `~Copyable` mechanics. That's what this note does.

Implication for DocC tutorial content (deferred to 0.1.x polish track): a worked example of the `second = File.Handle(first.underlying)` compile failure, showing the caller what the error message looks like and pointing to the consume-and-reconstruct option.

## References

- `Sources/Carrier Primitives/Carrier.swift` — protocol declaration
- `Sources/Carrier Primitives/Carrier where Underlying == Self.swift` — trivial-self default using `_read { yield self }`
- `forums-review-simulation-2026-04-24.md` post 2 (c2) — the objection this note addresses
- `capability-lift-pattern.md` §V5b — `~Copyable` quadrant considerations
- `self-projection-default-pattern.md` (swift-ownership-primitives) §Round-trip — the complementary ownership-layer pattern
- SE-0427 — noncopyable generics
- SE-0506 — noncopyable associated types
