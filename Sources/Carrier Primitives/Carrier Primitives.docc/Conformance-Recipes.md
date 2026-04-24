# Conformance Recipes

@Metadata {
    @TitleHeading("Carrier Primitives")
}

One recipe per `Copyable × Escapable` quadrant. Pick the shape that matches your type's characteristics, copy the template, adjust the `Underlying`.

## Overview

`Carrier<Underlying>` admits four conformance shapes depending on whether `Self` and `Underlying` suppress `Copyable` or `Escapable`. The protocol's getter and init annotations degrade gracefully across the grid — the concrete conformer omits `@_lifetime` annotations when `Underlying` is `Escapable` (Swift rejects them there) and includes them when `Underlying` is `~Escapable`.

All four recipes below follow the same disciplined shape:

- **Stored properties and the canonical initializer live in the type's body.** Per `[API-IMPL-008]`, the declaration body carries only the fields needed to store the value and the init that consumes the incoming underlying.
- **Protocol conformance lives in a standalone `extension`.** The `Carrier` conformance — associated-type bindings plus the `underlying` getter — is declared in `extension Foo: Carrier { ... }` rather than threaded into the struct declaration.
- **Nested names follow `Nest.Name`.** Identifier wrappers are `User.ID` (nested under the domain type), not `UserID` (a compound name). Resource wrappers nest under the resource's domain — e.g., `File.Handle` over `File.Descriptor`.

This article walks through all four quadrants. The trivial-self-carrier default (when `Underlying == Self`) applies only to Q1 and is covered at the end.

## Recipe Q1 — Copyable & Escapable

The ordinary case. Plain value-type `Underlying`: `Int`, `Double`, a struct, a class reference. The carrier itself is copyable.

```swift
struct User {
    var name: String
    var email: String
}

extension User {
    struct ID {
        var _storage: UInt64

        init(_ underlying: consuming UInt64) {
            self._storage = underlying
        }
    }
}

extension User.ID: Carrier {
    typealias Domain = User
    typealias Underlying = UInt64

    var underlying: UInt64 {
        borrowing get { _storage }
    }
}
```

**Requirements**:
- `struct User { ... }` — the domain type the phantom `Domain` reuses. `User` is an ordinary struct with its own fields; no empty tag types required.
- `struct ID { var _storage: UInt64; init(_ underlying: consuming UInt64) { ... } }` nested under `User` — body holds the storage and canonical init per `[API-IMPL-008]`.
- `extension User.ID: Carrier` declares the conformance; `typealias Domain = User` and `typealias Underlying = UInt64` bind the associated types; `borrowing get { _storage }` implements the getter.

**Omit** the `@_lifetime(borrow self)` annotation on the getter and the `@_lifetime(copy underlying)` annotation on the init — Swift rejects these on `Escapable` results.

**Siblings**: declare `struct Order { ... }` with its own `Order.ID` by the same pattern to obtain two phantom-discriminated carriers over the same `Underlying`. `User.ID` and `Order.ID` are distinguishable at the type level via their `Domain`.

**When to use**: any wrapper around a plain value type.

## Recipe Q2 — `~Copyable` & Escapable

`Underlying` is a move-only resource: file descriptor, unique handle, allocation owner. The carrier inherits `~Copyable` because copying the carrier would copy the underlying (forbidden).

```swift
enum File {}

extension File {
    struct Descriptor: ~Copyable {
        var raw: Int32
    }
}

extension File {
    struct Handle: ~Copyable {
        var _storage: File.Descriptor

        init(_ underlying: consuming File.Descriptor) {
            self._storage = underlying
        }
    }
}

extension File.Handle: Carrier {
    typealias Underlying = File.Descriptor

    var underlying: File.Descriptor {
        _read { yield _storage }
    }
}
```

**Requirements**:
- `struct Handle: ~Copyable` — suppress `Copyable` on the carrier. The struct's body still contains only storage and the canonical init.
- `extension File.Handle: Carrier` declares the conformance; `_read { yield _storage }` yields the stored `~Copyable` value by borrow without consuming it. A plain `borrowing get { _storage }` would fail to compile because `_storage` cannot be implicitly copied out.
- `init(_ underlying: consuming File.Descriptor)` — the `consuming` keyword is load-bearing: ownership transfers from caller to carrier.

**Omit** `@_lifetime` annotations — `Underlying` is still `Escapable`.

**Siblings**: `File` as a namespace already has two siblings here (`File.Descriptor` and `File.Handle`), so the naming satisfies `[API-NAME-001a]` without contrivance. Additional ecosystem types such as `File.Path` or `File.Mode` would slot into the same namespace.

**Round-trip note**: see <doc:Round-trip-Semantics> — for `~Copyable` Underlying, `C(c.underlying)` does not compile (the borrow from `.underlying` cannot satisfy a `consuming` parameter). Round-trip uses `let u = consume c; let c2 = C(u)` instead.

## Recipe Q3 — Copyable & `~Escapable`

`Underlying` is a scoped view or borrowed reference: a `Span`-like type, a lifetime-bounded pointer. The carrier is `~Escapable` because its lifetime is bounded by the underlying's scope.

```swift
enum Buffer {}

extension Buffer {
    struct View<Element>: ~Escapable {
        var _storage: Span<Element>

        @_lifetime(copy underlying)
        init(_ underlying: consuming Span<Element>) {
            self._storage = underlying
        }
    }
}

extension Buffer.View: Carrier {
    typealias Underlying = Span<Element>

    var underlying: Span<Element> {
        @_lifetime(borrow self)
        borrowing get { _storage }
    }
}
```

**Requirements**:
- `struct View<Element>: ~Escapable` — suppress `Escapable` on the carrier. The storage is a `Span<Element>`, which is itself `Copyable` but `~Escapable`.
- `@_lifetime(borrow self)` on the getter in the extension — required for `~Escapable` results.
- `@_lifetime(copy underlying)` on the init in the body — ties the carrier's lifetime to the underlying's scope.
- Getter uses plain `borrowing get { _storage }` (not `_read`) because `Span<Element>` is `Copyable`.

**Siblings**: `Buffer` here hosts `Buffer.View` alongside `Buffer.Scope` from recipe Q4, so the namespace has multiple inhabitants and `[API-NAME-001a]` is satisfied.

**When to use**: wrapping a view or borrowed pointer that has a lifetime bound shorter than the program's.

## Recipe Q4 — `~Copyable` & `~Escapable`

Both suppressions apply. The most restrictive shape — typical for move-only scoped references like a `~Copyable & ~Escapable` mutable borrow.

```swift
extension Buffer {
    struct Scope<Base: ~Copyable>: ~Copyable, ~Escapable {
        var _storage: Ownership.Inout<Base>

        @_lifetime(copy underlying)
        init(_ underlying: consuming Ownership.Inout<Base>) {
            self._storage = underlying
        }
    }
}

extension Buffer.Scope: Carrier where Base: ~Copyable {
    typealias Underlying = Ownership.Inout<Base>

    var underlying: Ownership.Inout<Base> {
        @_lifetime(borrow self)
        _read { yield _storage }
    }
}
```

**Requirements**:
- `struct Scope<Base: ~Copyable>: ~Copyable, ~Escapable` — both suppressions on the carrier; `Base: ~Copyable` on the generic parameter.
- `extension Buffer.Scope: Carrier where Base: ~Copyable` — the extension restates the `~Copyable` constraint on `Base` per `[MEM-COPY-004]`; without it, the extension implicitly reintroduces `Base: Copyable`.
- `_read { yield _storage }` — for `~Copyable` storage.
- `@_lifetime(borrow self)` on getter + `@_lifetime(copy underlying)` on init — for `~Escapable` results.

**When to use**: wrapping a scoped, move-only reference — the rare combined case. Most real code is Q1 or Q2; Q4 is for advanced ownership-primitives consumers.

## Trivial self-carrier default (Q1 only)

When `Underlying == Self`, the default extension in `Carrier Primitives` provides the getter and init for free:

```swift
extension Int: Carrier {
    typealias Underlying = Int
    // underlying and init(_:) provided by the default extension.
}
```

This is how the `Carrier Primitives Standard Library Integration` target conforms `Int`, `String`, `Bool`, and friends — a single `typealias Underlying = Self` line per stdlib type.

The default only applies to Q1 (`Copyable & Escapable`). For Q2–Q4, write the getter and init explicitly.

## Quadrant summary

| Quadrant | `Self` | `Underlying` | Getter form | `@_lifetime` |
|----------|--------|--------------|-------------|--------------|
| Q1 | Copyable, Escapable | Copyable, Escapable | `borrowing get { }` | Omit both |
| Q2 | `~Copyable`, Escapable | `~Copyable`, Escapable | `_read { yield }` | Omit both |
| Q3 | Copyable, `~Escapable` | Copyable, `~Escapable` | `borrowing get { }` + `@_lifetime(borrow self)` | Required on both |
| Q4 | `~Copyable`, `~Escapable` | `~Copyable`, `~Escapable` | `_read { yield }` + `@_lifetime(borrow self)` | Required on both |

## See Also

- ``Carrier``
- <doc:Understanding-Carriers>
- <doc:Round-trip-Semantics>
- <doc:Carrier-vs-RawRepresentable>
