// Default extension covering the Q4 quadrant (~Copyable & ~Escapable
// Self) of trivial self-carriers. A value type that is both `~Copyable`
// and `~Escapable` conforming `where Underlying == Self` gets
// `underlying` and `init(_:)` from this default with only
// `typealias Underlying = Self`.
//
// `@_lifetime` annotations are required because Self's result type is
// ~Escapable; the annotations express the lifetime dependency.

public import Carrier_Primitive

extension Carrier.`Protocol` where Underlying == Self, Self: ~Copyable & ~Escapable {
    /// Protocol-required underlying accessor (default implementation: returns self).
    @_alwaysEmitIntoClient
    public var underlying: Self {
        @_lifetime(borrow self)
        _read { yield self }
    }

    /// Protocol-required init (default implementation: assigns underlying as self).
    @_alwaysEmitIntoClient
    @_lifetime(copy underlying)
    public init(_ underlying: consuming Self) {
        self = underlying
    }
}
