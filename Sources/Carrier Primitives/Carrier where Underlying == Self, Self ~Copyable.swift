// Default extension covering the Q2 quadrant (~Copyable, Escapable
// Self) of trivial self-carriers. A `~Copyable` value type conforming
// `where Underlying == Self` gets `underlying` and `init(_:)` from this
// default with only `typealias Underlying = Self`.
//
// No `@_lifetime` annotations: Self remains Escapable in this
// quadrant, and lifetime annotations on Escapable result types are
// rejected by the compiler. The `_read { yield self }` accessor is
// still required (rather than `borrowing get { self }`) because
// returning self from a `borrowing` accessor consumes self for
// ~Copyable Self.

extension Carrier where Underlying == Self, Self: ~Copyable {
    public var underlying: Self {
        _read { yield self }
    }

    public init(_ underlying: consuming Self) {
        self = underlying
    }
}
