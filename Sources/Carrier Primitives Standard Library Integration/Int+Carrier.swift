public import Carrier_Primitives

extension Int: Carrier.`Protocol` {
    /// The Underlying type for the Carrier conformance.
    public typealias Underlying = Int
    // `underlying` and `init(_:)` satisfied by the default
    // `extension Carrier where Underlying == Self`.
}
