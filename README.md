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

Local DocC preview requires the canonical multi-target pipeline per
`[DOC-019a]` / `[DOC-102]`. Bare `swift package preview-documentation` will
not resolve the `Carrier` symbol — Test Support's `@_exported public import`
shadows the umbrella unless explicitly excluded.

```sh
RAW=.build/docs-work/raw
ISO=.build/docs-work/isolated
mkdir -p "$RAW" "$ISO"

swift build -c debug --target "Carrier Primitives" \
    -Xswiftc -emit-symbol-graph \
    -Xswiftc -emit-symbol-graph-dir -Xswiftc "$RAW"

python3 ../../swift-institute/Scripts/patch-umbrella-symbol-graph.py \
    --symbol-graph-dir "$RAW" \
    --umbrella-module Carrier_Primitives \
    --output-dir "$ISO" \
    --exclude-module Carrier_Primitives_Test_Support

xcrun docc preview "Sources/Carrier Primitives/Carrier Primitives.docc" \
    --additional-symbol-graph-dir "$ISO" \
    --fallback-display-name "Carrier Primitives" \
    --fallback-bundle-identifier swift-carrier-primitives.Carrier-Primitives \
    --port 8765
```

Requires a sibling `swift-institute` checkout at `../../swift-institute`
for the patch script. CI runs the equivalent `docc convert` flow via the
centralized `swift-docs.yml` reusable workflow.

---

## Further reading

Design rationale, decision records, and empirical verification live in
the package's `Research/` and `Experiments/` directories per `[RES-002]`
/ `[EXP-002]` / `[DOC-101]` — DocC is the consumer surface; research and
experiments are the contributor surface.

**Research** (selection):

- [`capability-lift-pattern.md`](Research/capability-lift-pattern.md) — the parent pattern characterization (RECOMMENDATION, v1.3.0)
- [`carrier-vs-rawrepresentable-comparative-analysis.md`](Research/carrier-vs-rawrepresentable-comparative-analysis.md) — nine-dimension comparative analysis (DECISION)
- [`capability-lift-pattern-academic-foundations.md`](Research/capability-lift-pattern-academic-foundations.md) — Tier 3 academic survey (Reynolds parametricity, Wadler free theorems, fibration structure, lightweight higher-kinded encoding)
- [`mutability-design-space.md`](Research/mutability-design-space.md) — Carrier mutability decision (DEFERRED)
- [`dynamic-member-lookup-decision.md`](Research/dynamic-member-lookup-decision.md) — `@dynamicMemberLookup` rejection record
- [`round-trip-semantics-noncopyable-underlyings.md`](Research/round-trip-semantics-noncopyable-underlyings.md) — semantic property of `~Copyable` Underlyings

**Experiments** (selection):

- [`capability-lift-pattern/`](Experiments/capability-lift-pattern/) — six variants V0–V5 (CONFIRMED)
- [`span-carrier-conformance/`](Experiments/span-carrier-conformance/) — Q3 conformance probe
- [`relax-trivial-self-default/`](Experiments/relax-trivial-self-default/) — quadrant coverage validation
- [`dynamic-member-lookup-quadrants/`](Experiments/dynamic-member-lookup-quadrants/) — asymmetric-quadrant rejection evidence

Full catalog in [`Research/_index.json`](Research/_index.json) and
[`Experiments/_index.json`](Experiments/_index.json).

---

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
