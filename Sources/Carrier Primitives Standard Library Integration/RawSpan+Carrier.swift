public import Carrier_Primitives

extension RawSpan: Carrier {
    public typealias Underlying = RawSpan

    public var underlying: RawSpan {
        @_lifetime(borrow self)
        _read { yield self }
    }

    @_lifetime(copy underlying)
    public init(_ underlying: consuming RawSpan) {
        self = underlying
    }
}
