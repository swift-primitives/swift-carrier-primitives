import Carrier_Primitives_Test_Support
import Testing

// MutableSpan<Element> is ~Escapable. Conformance is a one-line
// typealias backed by `extension Carrier where Underlying == Self,
// Self: ~Escapable`.

@Suite
struct `MutableSpan+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `MutableSpan+Carrier Tests`.Unit {

    @Test
    func `MutableSpan underlying yields self via _read coroutine`() {
        var bytes: [UInt8] = [10, 20, 30]
        unsafe bytes.withUnsafeMutableBufferPointer { buffer in
            let span = unsafe MutableSpan<UInt8>(_unsafeElements: buffer)
            #expect(span.underlying.count == 3)
        }
    }
}

extension `MutableSpan+Carrier Tests`.`Edge Case` {

    @Test
    func `MutableSpan<UInt8> conforms at the type level`() {
        func _requireCarrier<T: Carrier.`Protocol` & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(MutableSpan<UInt8>.self)
        #expect(Bool(true))
    }

    @Test
    func `MutableSpan underlying preserves empty buffer`() {
        var bytes: [UInt8] = []
        unsafe bytes.withUnsafeMutableBufferPointer { buffer in
            let span = unsafe MutableSpan<UInt8>(_unsafeElements: buffer)
            let isEmpty = span.underlying.isEmpty
            #expect(isEmpty)
        }
    }
}
