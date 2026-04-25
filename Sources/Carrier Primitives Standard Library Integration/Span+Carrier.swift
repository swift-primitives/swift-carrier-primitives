public import Carrier_Primitives

extension Span: Carrier {
    public typealias Underlying = Span<Element>

    public var underlying: Span<Element> {
        @_lifetime(borrow self)
        _read { yield self }
    }

    @_lifetime(copy underlying)
    public init(_ underlying: consuming Span<Element>) {
        self = underlying
    }
}
