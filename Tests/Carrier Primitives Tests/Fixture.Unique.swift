import Carrier_Primitives

extension Fixture {
    /// Quadrant 2: ~Copyable & Escapable Underlying.
    ///
    /// The carrier is `~Copyable` because its Underlying is. Underlying
    /// remains Escapable, so `@_lifetime` annotations are still
    /// omitted. The getter uses a `_read { yield }` coroutine to
    /// provide borrowing access to the `~Copyable` stored value.
    struct Unique: ~Copyable, Carrier {
        typealias Underlying = Fixture.Unique.Resource

        var _storage: Fixture.Unique.Resource

        var underlying: Fixture.Unique.Resource {
            _read { yield _storage }
        }

        init(_ underlying: consuming Fixture.Unique.Resource) {
            self._storage = underlying
        }
    }
}
