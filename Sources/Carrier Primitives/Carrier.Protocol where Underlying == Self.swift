// Carrier.Protocol where Underlying == Self.swift
// Default implementation for trivial self-carriers — types where
// Underlying == Self.

extension Carrier.`Protocol` where Underlying == Self {
    /// Default: a trivial self-carrier's `underlying` IS its own storage.
    ///
    /// Uses `_read { yield self }` instead of `borrowing get { self }`.
    /// The `borrowing get` form fails in a generic context where Self
    /// is suppressed-`~Copyable` (the generic extension doesn't know
    /// whether Self admits copying, so it treats the `return self` as
    /// a consume). `_read` yields the stored value by borrow without
    /// consuming, satisfying the protocol's borrowing-get requirement
    /// for both Copyable and ~Copyable Self.
    public var underlying: Self {
        _read { yield self }
    }

    /// Default: a trivial self-carrier is constructed by assigning the
    /// consumed underlying into self.
    public init(_ underlying: consuming Self) {
        self = underlying
    }
}
