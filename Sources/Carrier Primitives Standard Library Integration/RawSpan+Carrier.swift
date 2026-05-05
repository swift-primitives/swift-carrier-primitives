public import Carrier_Primitives

extension RawSpan: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = RawSpan
    // `underlying` and `init(_:)` satisfied by the default
    // `extension Carrier where Underlying == Self, Self: ~Escapable`.
}
