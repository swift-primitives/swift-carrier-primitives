public import Carrier_Primitives

extension MutableRawSpan: Carrier {
    public typealias Underlying = MutableRawSpan
    // `underlying` and `init(_:)` satisfied by the default
    // `extension Carrier where Underlying == Self, Self: ~Escapable`.
}
