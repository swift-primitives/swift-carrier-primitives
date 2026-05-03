// Default extension covering the Q4 quadrant (~Copyable & ~Escapable
// Self) of trivial self-carriers. A value type that is both `~Copyable`
// and `~Escapable` conforming `where Underlying == Self` gets
// `underlying` and `init(_:)` from this default with only
// `typealias Underlying = Self`.
//
// `@_lifetime` annotations are required because Self's result type is
// ~Escapable; the annotations express the lifetime dependency.

extension Carrier.`Protocol` where Underlying == Self, Self: ~Copyable & ~Escapable {
    public var underlying: Self {
        @_lifetime(borrow self)
        _read { yield self }
    }

    @_lifetime(copy underlying)
    public init(_ underlying: consuming Self) {
        self = underlying
    }
}
