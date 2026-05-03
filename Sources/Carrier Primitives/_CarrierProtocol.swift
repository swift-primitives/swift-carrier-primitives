// _CarrierProtocol.swift
// Hoisted form of the Carrier protocol per [API-IMPL-009] —
// Swift does not allow protocols nested inside types, so the protocol
// lives at module scope and the user-facing path `Carrier.`Protocol``
// is provided by a typealias on the `Carrier` namespace (see Carrier.swift).
//
// Consumers SHOULD use `Carrier.`Protocol`` (canonical) or `Carrying`
// (alias) instead of this hoisted name.

/// A type that carries an `Underlying` value, optionally tagged by a
/// phantom `Domain`.
///
/// ## Example
///
/// ```swift
/// // Trivial self-carrier — the default extension provides
/// // `underlying` and `init(_:)`.
/// extension Cardinal: Carrier.`Protocol` {
///     typealias Underlying = Cardinal
/// }
/// ```
///
/// For the full reference — the four-quadrant grid, round-trip
/// semantics, conformance forms, and generic-consumer shapes — see
/// ``Carrier_Primitives/Carrier``.
public protocol _CarrierProtocol<Underlying>: ~Copyable, ~Escapable {
    /// The phantom discriminator distinguishing otherwise-
    /// indistinguishable carriers of the same `Underlying`.
    ///
    /// Defaults to `Never` for trivial self-carriers; authored
    /// wrappers override it with the domain type they belong to
    /// (e.g., `User.ID.Domain == User`).
    associatedtype Domain: ~Copyable & ~Escapable = Never

    /// The wrapped value type.
    associatedtype Underlying: ~Copyable & ~Escapable

    /// Borrowing access to the carried underlying value.
    ///
    /// Conformers implementing the getter for `~Copyable` Underlying
    /// use a `_read { yield ... }` coroutine; `Copyable` Underlying
    /// permits a plain `borrowing get`.
    var underlying: Underlying {
        @_lifetime(borrow self)
        borrowing get
    }

    /// Constructs a carrier from an underlying value.
    ///
    /// The `consuming` parameter transfers ownership from caller to
    /// carrier — load-bearing for `~Copyable` Underlying and a no-op
    /// for `Copyable`.
    @_lifetime(copy underlying)
    init(_ underlying: consuming Underlying)
}
