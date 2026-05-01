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
    .package(url: "https://github.com/swift-primitives/swift-carrier-primitives.git", branch: "main")
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
| `Carrier Primitives Standard Library Integration` | `Sources/Carrier Primitives Standard Library Integration/` | Conforms 28 stdlib primitive types (integer families, floating-point, `Bool`, `String`, `Substring`, `Character`, `Unicode.Scalar`, `StaticString`, `Duration`, `ObjectIdentifier`, `Never`, plus the `~Escapable` span types `Span` / `MutableSpan` / `RawSpan` / `MutableRawSpan`) to Carrier as trivial self-carriers. |
| `Carrier Primitives Test Support` | `Tests/Support/` | Re-exports the main targets for test consumers. |

Import the narrowest product you need: `Carrier Primitives` for the protocol alone, or `Carrier Primitives Standard Library Integration` (which `@_exported public import`s the main target) when you want bare stdlib values to reach `some Carrier<Int>` / `some Carrier<String>` API sites.

Foundation-free.

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

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
