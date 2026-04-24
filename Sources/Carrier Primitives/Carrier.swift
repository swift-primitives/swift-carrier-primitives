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
    /// The phantom domain that tags this carrier.
    ///
    /// Defaults to `Never` for trivial self-carriers (bare value types
    /// that carry themselves with no phantom distinction). Tagged-family
    /// carriers override this to their Tag type — e.g.,
    /// `Tagged<UserTag, Int>.Domain == UserTag`, allowing generic
    /// consumers to distinguish `UserTag`-tagged Ints from `OrderTag`-
    /// tagged Ints at the type level.
    associatedtype Domain: ~Copyable & ~Escapable = Never

    /// The wrapped value type.
    associatedtype Underlying: ~Copyable & ~Escapable

    /// Borrowing access to the carried underlying value.
    ///
    /// The returned value's lifetime is bounded by `self`. For
    /// `~Copyable` Underlying, conformers implement this via a
    /// `_read { yield ... }` coroutine; for `Copyable` Underlying, a
    /// plain `borrowing get { ... }` suffices (the `@_lifetime` and
    /// `borrowing` annotations on the getter requirement are omitted
    /// in the conformer when Underlying is Escapable, since the
    /// attribute is rejected on Escapable results).
    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    /// Constructs a carrier from an underlying value.
    ///
    /// The `consuming` parameter transfers ownership from caller to
    /// carrier — required for `~Copyable` Underlying and a no-op for
    /// `Copyable` Underlying. The `@_lifetime(copy underlying)`
    /// annotation ties the carrier's lifetime to the underlying's
    /// scope when Underlying is `~Escapable`.
    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
