public import Carrier_Primitives

extension Int: Carrier {
    public typealias Underlying = Int
    // `underlying` and `init(_:)` satisfied by the default
    // `extension Carrier where Underlying == Self` in
    // Carrier+Trivial.swift.
}
