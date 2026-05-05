public import Carrier_Primitives

extension Never: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = Never
}
