public import Carrier_Primitives

extension MutableSpan: Carrier {
    public typealias Underlying = MutableSpan<Element>

    public var underlying: MutableSpan<Element> {
        @_lifetime(borrow self)
        _read { yield self }
    }

    @_lifetime(copy underlying)
    public init(_ underlying: consuming MutableSpan<Element>) {
        self = underlying
    }
}
