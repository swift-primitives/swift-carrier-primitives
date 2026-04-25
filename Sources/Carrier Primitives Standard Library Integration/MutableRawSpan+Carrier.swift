public import Carrier_Primitives

extension MutableRawSpan: Carrier {
    public typealias Underlying = MutableRawSpan

    public var underlying: MutableRawSpan {
        @_lifetime(borrow self)
        _read { yield self }
    }

    @_lifetime(copy underlying)
    public init(_ underlying: consuming MutableRawSpan) {
        self = underlying
    }
}
