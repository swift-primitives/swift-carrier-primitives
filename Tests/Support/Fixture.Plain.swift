public import Carrier_Primitives

extension Fixture {
    /// Quadrant 1: Copyable & Escapable Underlying.
    ///
    /// The simplest carrier — plain storage + plain getter + plain
    /// init. `@_lifetime` annotations are omitted because `Int` is
    /// Escapable (the attribute is rejected on Escapable results).
    /// `Domain` defaults to `Never`.
    public struct Plain {
        var _storage: Int

        public init(_ underlying: consuming Int) {
            self._storage = underlying
        }
    }
}

extension Fixture.Plain: Carrier.`Protocol` {
    public typealias Underlying = Int

    public var underlying: Int {
        borrowing get { _storage }
    }
}
