public import Carrier_Primitives

extension Fixture {
    /// Quadrant 4: ~Copyable & ~Escapable Underlying.
    ///
    /// Both suppressions apply. The `@_lifetime` annotations on the
    /// getter and init are required (unlike Q1/Q2, where Escapable
    /// Underlying rejects them). `_read` yields the `~Copyable` stored
    /// value by borrow with its lifetime scoped to self.
    public struct Scoped: ~Copyable, ~Escapable {
        var _storage: Fixture.Scoped.Resource

        @_lifetime(copy underlying)
        public init(_ underlying: consuming Fixture.Scoped.Resource) {
            self._storage = underlying
        }
    }
}

extension Fixture.Scoped: Carrier {
    public typealias Underlying = Fixture.Scoped.Resource

    public var underlying: Fixture.Scoped.Resource {
        @_lifetime(borrow self)
        _read { yield _storage }
    }
}
