public import Carrier_Primitives

extension StaticString: Carrier.`Protocol` {
    public typealias Underlying = StaticString
}
