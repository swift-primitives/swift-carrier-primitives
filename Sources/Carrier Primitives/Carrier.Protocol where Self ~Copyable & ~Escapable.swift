// Carrier.Protocol where Self ~Copyable & ~Escapable.swift
// Default throwing init available to every Carrier conformer.

extension Carrier.`Protocol` where Self: ~Copyable & ~Escapable {
    /// Constructs a carrier from an underlying value, validating it first through the supplied closure.
    ///
    /// Throws the closure's error type when validation fails; otherwise
    /// delegates to the existing non-throwing `init(_ underlying:)`
    /// requirement.
    ///
    /// Every Carrier conformer inherits this init for free — domain
    /// types do not need to declare per-domain throwing inits.
    @_lifetime(copy underlying)
    public init<E: Swift.Error>(
        _ underlying: consuming Underlying,
        validate: (borrowing Underlying) throws(E) -> Void
    ) throws(E) {
        try validate(underlying)
        self.init(underlying)
    }
}
