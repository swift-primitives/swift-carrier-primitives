# Round-trip Semantics

@Metadata {
    @TitleHeading("Carrier Primitives")
}

Why `C(c.underlying)` works for `Copyable` Underlyings but not for `~Copyable` ones — and what to do instead.

## Overview

`Carrier.`Protocol`<Underlying>` exposes `underlying` via a **borrowing** getter and accepts `consuming Underlying` in its init. A naive reading of that pair suggests round-trip: read the underlying, rebuild a new carrier from it, original still valid. That reading holds for `Copyable` Underlyings. For `~Copyable` ones, the round-trip weakens in a specific way.

This article documents the weakening.

## The asymmetry

The getter yields a **borrow** of the `Underlying`:

```swift
var underlying: Underlying {
    @_lifetime(borrow self)
    borrowing get  // ← returns a borrow, not an owned value
}
```

The init consumes an **owned** `Underlying`:

```swift
@_lifetime(copy underlying)
init(_ underlying: consuming Underlying)  // ← takes ownership, not a borrow
```

For `Copyable` Underlying this asymmetry is invisible: any borrowed value can be copied into a fresh owned one. For `~Copyable` Underlying there is no implicit copy, so a borrow cannot be fed into the consuming init.

## What works and what does not

| Scenario | `Copyable Underlying` | `~Copyable Underlying` |
|----------|-----------------------|------------------------|
| Read `carrier.underlying`, build new carrier via `C(carrier.underlying)` with `carrier` still valid | Works — copy is implicit | Compile error — borrow cannot satisfy `consuming` |
| Consume carrier to extract owned underlying, pass to `C.init(_:)` | Works (destroys original) | Works (destroys original) |
| Own a *separate* fresh `Underlying` elsewhere, pass to `C.init(_:)` | Works | Works |
| Round-trip `self.underlying → C(self.underlying)` with `self` preserved | Works | Impossible by design |

The last row is the asymmetry. It's not a bug — it's linear-type discipline. `~Copyable` values have exactly one owner; round-trip-with-original-preserved is a Copyable property, not a universal carrier property.

## The correct pattern for `~Copyable` Underlyings

The Q2 recipe in <doc:Conformance-Recipes> sets up `File.Handle` as a carrier over a `~Copyable File.Descriptor`. The snippets below use the same shape.

### Option A — Consume and reconstruct

```swift
var handle: File.Handle = ...
let descriptor = consume handle                  // destroys handle; yields its descriptor
// ... inspect or transform descriptor ...
let rebuilt = File.Handle(descriptor)            // consumes descriptor
```

Canonical `~Copyable` pattern: one carrier in, one carrier out, the path passes through an owned value.

### Option B — Supply a fresh Underlying

```swift
let freshDescriptor = File.Descriptor(raw: openedByCaller)
let handle = File.Handle(freshDescriptor)
```

`freshDescriptor` is not any pre-existing carrier's `.underlying` — it's independently owned. The consuming init works cleanly.

### What does NOT work

```swift
// Compile error for ~Copyable Underlying:
let first: File.Handle = ...
let second = File.Handle(first.underlying)       // ✗ cannot consume a borrow
```

`first.underlying` is a borrowed value; `init(_:)` wants a consumed one. The Swift compiler rejects this at the borrow-checker level.

## Why this isn't a bug

- **Linearity**: `~Copyable` types are by design unique. Copying or duplicating — which is what preserving-the-original-while-reconstructing would require — is forbidden.
- **Ownership transfer**: `consuming init` is correct. An alternative `init(borrowing:)` would need to *copy* the borrowed value to store it in the new carrier — again, forbidden.
- **`_read { yield self }` in the trivial-self default**: the default extension uses `_read` precisely because it works for both Copyable and `~Copyable` Self, while `borrowing get { self }` would require `Self: Copyable`.

## Implications for generic code

A generic function over `some Carrier.`Protocol`<Underlying>` that wants to "rebuild" a carrier must choose:

1. **Always safe?** Constrain on `where Underlying: Copyable` — the round-trip pattern works cleanly.
2. **Consume the carrier?** Generic over `~Copyable` works — the function owns the carrier and can extract the underlying.
3. **Read-only?** Don't rebuild. Use `borrowing` throughout and leave carrier construction to the caller.

Most Carrier-consuming algorithms are category 3 (read-only). The round-trip asymmetry only matters when the algorithm transforms a carrier in place.

## See Also

- ``Carrier``
- <doc:Understanding-Carriers>
- <doc:Conformance-Recipes>
