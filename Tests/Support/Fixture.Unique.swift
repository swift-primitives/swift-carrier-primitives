public import Carrier_Primitives

extension Fixture {
    /// Quadrant 2: ~Copyable & Escapable Underlying.
    ///
    /// The carrier is `~Copyable` because its Underlying is. Underlying
    /// remains Escapable, so `@_lifetime` annotations are still
    /// omitted. The getter uses a `_read { yield }` coroutine to
    /// provide borrowing access to the `~Copyable` stored value.
    public struct Unique: ~Copyable {
        var _storage: Fixture.Unique.Resource

        public init(_ underlying: consuming Fixture.Unique.Resource) {
            self._storage = underlying
        }
    }
}

extension Fixture.Unique: Carrier {
    public typealias Underlying = Fixture.Unique.Resource

    public var underlying: Fixture.Unique.Resource {
        _read { yield _storage }
    }
}
