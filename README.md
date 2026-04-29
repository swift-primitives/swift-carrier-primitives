# Carrier Primitives

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

Unified super-protocol for phantom-typed value wrappers — `Carrier<Underlying>` spans Cardinal, Ordinal, Hash.Value, Tagged, and move-only resource wrappers across all four `Copyable × Escapable` quadrants.

---

## Quick Start

Nest an identifier wrapper under a real domain type and conform it to `Carrier` via a standalone extension. The phantom `Domain` reuses the existing type as a compile-time tag — `User.ID` and `Order.ID` both wrap `UInt64`, but generic code distinguishes them:

```swift
import Carrier_Primitives

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

The same recipe works for `~Copyable` resource wrappers — a shape `RawRepresentable` cannot express at all:

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

Both `User.ID` and `File.Handle` reach `some Carrier<UInt64>` / `some Carrier<File.Descriptor>` API sites without additional plumbing. The DocC tutorial walks through the first example step by step; the Conformance Recipes article covers the other three `Copyable × Escapable` quadrants; the Carrier vs RawRepresentable article documents where the two protocols diverge.

---

## Installation

```swift
dependencies: [
    .package(url: "https://github.com/swift-primitives/swift-carrier-primitives.git", from: "0.1.0")
]
```

```swift
.target(
    name: "App",
    dependencies: [
        .product(name: "Carrier Primitives", package: "swift-carrier-primitives"),
    ]
)
```

Requires Swift 6.3.1 and macOS 26 / iOS 26 / tvOS 26 / watchOS 26 / visionOS 26 (or the matching Linux / Windows toolchain).

---

## Architecture

Three library products, zero external dependencies.

| Product | Target | Purpose |
|---------|--------|---------|
| `Carrier Primitives` | `Sources/Carrier Primitives/` | The `Carrier<Underlying>` protocol + `extension Carrier where Underlying == Self` default for trivial self-carriers. |
| `Carrier Primitives Standard Library Integration` | `Sources/Carrier Primitives Standard Library Integration/` | Conforms 24 stdlib primitive types (integer families, floating-point, `Bool`, `String`, `Substring`, `Character`, `Unicode.Scalar`, `StaticString`, `Duration`, `ObjectIdentifier`, `Never`) to Carrier as trivial self-carriers. |
| `Carrier Primitives Test Support` | `Tests/Support/` | Re-exports the main targets for test consumers. |

Per `[MOD-015]` consumer-import-precision, import the narrowest product you need: `Carrier Primitives` for the protocol alone, or `Carrier Primitives Standard Library Integration` (which `@_exported public import`s the main target) when you want bare stdlib values to reach `some Carrier<Int>` / `some Carrier<String>` API sites.

Foundation-free per `[PRIM-FOUND-001]`.

---

## Platform Support

| Platform | Status |
|----------|--------|
| macOS 26 | Full support |
| Linux | Full support |
| Windows | Full support |
| iOS / tvOS / watchOS / visionOS | Supported |
| Swift Embedded | Supported |

---

## Related Packages

**Used By**:

- [swift-tagged-primitives](https://github.com/swift-primitives/swift-tagged-primitives) — `Tagged<Tag, V>` is the canonical parametric implementation of Carrier. The `Tagged: Carrier` conformance lives in tagged-primitives per the ecosystem pattern (conformances of a type to a foreign protocol live in the conformer's home package).
- [swift-cardinal-primitives](https://github.com/swift-primitives/swift-cardinal-primitives), [swift-ordinal-primitives](https://github.com/swift-primitives/swift-ordinal-primitives), [swift-hash-primitives](https://github.com/swift-primitives/swift-hash-primitives) — candidates for Carrier adoption as trivial self-carriers.

---

## Contributing

Documentation building and deployment is handled by the centralized
`swift-institute/.github/.github/workflows/swift-docs.yml` reusable
workflow on every push to `main`. Local DocC preview is not currently
shipped as a per-package script — bare `swift package preview-documentation`
hits a known cross-module symbol-pool ambiguity on multi-target umbrella
packages with `@_exported public import` (Test Support shadows the
umbrella's `Carrier` symbol). Work the docs against rendered CI output,
or invoke the canonical pipeline from `swift-institute/Scripts/` if a
centralized local-preview helper has landed (tracked in the
carrier-launch skill-incorporation backlog).

---

## Further reading

Per `[DOC-101]` the DocC catalog is the consumer surface — **start
there for usage**. Built and served by Swift Package Index from each
tagged release.

For contributors and ecosystem maintainers, the canonical design
rationale lives at
[`Research/Carrier Primitives Vision.md`](Research/Carrier%20Primitives%20Vision.md):
ten-part narrative covering the problem, the protocol surface, Tagged
as the canonical Carrier, the comparison vs RawRepresentable, the
four-quadrant operationalization, the role-class taxonomy, round-trip
semantics, the read-only-by-design rationale, theoretical foundations,
and open questions. The 14 `sli-*.md` files alongside record per-
stdlib-type SLI skip decisions; full index in
[`Research/_index.json`](Research/_index.json).

Empirical verification sits in
[`Experiments/_index.json`](Experiments/_index.json) — V0–V5 of the
capability-lift pattern (CONFIRMED), the dynamic-member-lookup
quadrant rejection evidence, the Q3 span-Carrier conformance probe,
and the trivial-self default quadrant coverage.

---

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
