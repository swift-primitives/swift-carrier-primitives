public import Carrier_Primitives

extension Unicode.Scalar: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = Unicode.Scalar
}
