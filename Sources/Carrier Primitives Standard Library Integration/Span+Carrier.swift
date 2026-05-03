public import Carrier_Primitives

extension Span: Carrier.`Protocol` {
    public typealias Underlying = Span<Element>
    // `underlying` and `init(_:)` satisfied by the default
    // `extension Carrier where Underlying == Self, Self: ~Escapable`.
}
