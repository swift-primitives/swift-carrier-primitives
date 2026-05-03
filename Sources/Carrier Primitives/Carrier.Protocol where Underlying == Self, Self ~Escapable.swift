// Default extension covering the Q3 quadrant (Copyable, ~Escapable
// Self) of trivial self-carriers. Conformers in this quadrant — Span,
// MutableSpan, RawSpan, MutableRawSpan, and any future ~Escapable
// stdlib type — get `underlying` and `init(_:)` from this default with
// only `typealias Underlying = Self`.
//
// `@_lifetime(borrow self) _read { yield self }` and `@_lifetime(copy
// underlying) init(_:)` are required for ~Escapable Self because the
// witness's result type is ~Escapable; the lifetime annotations express
// the dependency. The colon-less filename ("Self ~Escapable" rather
// than "Self: ~Escapable") avoids Windows' reserved `:` while keeping
// the where-clause shape readable. `Underlying == Self` is placed first
// in both the filename and the where clause so all four trivial-self
// default extensions share the same prefix and group lexically.

extension Carrier.`Protocol` where Underlying == Self, Self: ~Escapable {
    public var underlying: Self {
        @_lifetime(borrow self)
        _read { yield self }
    }

    @_lifetime(copy underlying)
    public init(_ underlying: consuming Self) {
        self = underlying
    }
}
