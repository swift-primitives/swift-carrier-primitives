import Carrier_Primitives

extension Fixture {
    /// Quadrant 1: Copyable & Escapable Underlying.
    ///
    /// The simplest carrier — plain storage + plain getter + plain
    /// init. `@_lifetime` annotations are omitted because `Int` is
    /// Escapable (the attribute is rejected on Escapable results).
    /// `Domain` defaults to `Never`.
    struct Plain: Carrier {
        typealias Underlying = Int

        var _storage: Int

        var underlying: Int {
            borrowing get { _storage }
        }

        init(_ underlying: consuming Int) {
            self._storage = underlying
        }
    }
}
