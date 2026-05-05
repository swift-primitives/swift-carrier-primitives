public import Carrier_Primitives

extension MutableSpan: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = MutableSpan<Element>
    // `underlying` and `init(_:)` satisfied by the default
    // `extension Carrier where Underlying == Self, Self: ~Escapable`.
}
