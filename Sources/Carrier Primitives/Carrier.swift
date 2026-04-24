// Carrier.swift
// The Carrier super-protocol — a unified abstraction over phantom-typed
// value carriers across all four Copyable × Escapable quadrants.

/// A type that carries an `Underlying` value, optionally tagged by a
/// phantom `Domain`.
///
/// The canonical carrier relationship: an instance of a Carrier has a
/// readable `Underlying` value and can be constructed from one. Bare
/// value types are "trivial carriers" (Domain = Never); Tagged wrappers
/// are tag-bearing carriers (Domain = Tag). The same protocol covers
/// both shapes, plus `~Copyable` and `~Escapable` Underlyings.
///
/// ## Shape
///
/// ```swift
/// public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
///     associatedtype Domain:     ~Copyable & ~Escapable
///     associatedtype Underlying: ~Copyable & ~Escapable
///
///     var underlying: Underlying { borrowing get }
///     init(_ underlying: consuming Underlying)
/// }
/// ```
///
/// The `borrowing get` + `consuming init(_:)` pair handles all four
/// quadrants uniformly:
///
/// - `Copyable` & `Escapable`: read copies, init consumes (no-op for
///   copyable values).
/// - `~Copyable` & `Escapable`: read borrows (no copy), init consumes
///   ownership.
/// - `Copyable` & `~Escapable`: read borrows with scoped lifetime, init
///   consumes.
/// - `~Copyable` & `~Escapable`: read borrows with scoped lifetime, init
///   consumes.
///
/// ## Semantic note — round-trip
///
/// For `Copyable` Underlying, `T(carrier.underlying)` round-trips
/// cleanly: the read copies, the init consumes a copy. For `~Copyable`
/// Underlying, "round-trip" reads as "inspect then reconstruct from a
/// fresh consumed value" — the extracted borrow cannot itself be
/// consumed. This is the linear-type weakening of the round-trip
/// property; conformers for `~Copyable` Underlyings expose the carrier
/// abstraction in the inspect-then-rebuild sense rather than the
/// extract-then-reinsert sense.
///
/// ## Adoption
///
/// This package declares only the protocol. Conformances live in the
/// home package of each conforming type:
///
/// - `Tagged: Carrier` lives in `swift-tagged-primitives` (which
///   depends on this package).
/// - `Cardinal: Carrier`, `Ordinal: Carrier`, `Hash.Value: Carrier`
///   etc. live in their respective packages when and if they adopt
///   the super-protocol.
///
/// See `Research/capability-lift-pattern.md` for the design analysis
/// and `Experiments/capability-lift-pattern/` for variant verdicts.
public protocol Carrier<Underlying>: ~Copyable, ~Escapable {
    associatedtype Domain:     ~Copyable & ~Escapable
    associatedtype Underlying: ~Copyable & ~Escapable

    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
