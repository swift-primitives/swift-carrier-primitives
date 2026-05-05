public import Carrier_Primitives

extension String: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = String
}
