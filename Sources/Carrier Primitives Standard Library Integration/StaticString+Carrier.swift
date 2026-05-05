public import Carrier_Primitives

extension StaticString: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = StaticString
}
