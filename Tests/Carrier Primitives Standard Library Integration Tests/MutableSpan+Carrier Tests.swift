import Testing
import Carrier_Primitives_Test_Support

// MutableSpan<Element> is ~Escapable. Conformance ships explicit
// @_lifetime witnesses in MutableSpan+Carrier.swift.

@Suite("MutableSpan+Carrier")
struct MutableSpanCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension MutableSpanCarrierTests.Unit {

    @Test
    func `MutableSpan underlying yields self via _read coroutine`() {
        var bytes: [UInt8] = [10, 20, 30]
        unsafe bytes.withUnsafeMutableBufferPointer { buffer in
            let span = unsafe MutableSpan<UInt8>(_unsafeElements: buffer)
            #expect(span.underlying.count == 3)
        }
    }
}

extension MutableSpanCarrierTests.`Edge Case` {

    @Test
    func `MutableSpan<UInt8> conforms at the type level`() {
        func _requireCarrier<T: Carrier & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(MutableSpan<UInt8>.self)
        #expect(Bool(true))
    }

    @Test
    func `MutableSpan underlying preserves empty buffer`() {
        var bytes: [UInt8] = []
        unsafe bytes.withUnsafeMutableBufferPointer { buffer in
            let span = unsafe MutableSpan<UInt8>(_unsafeElements: buffer)
            #expect(span.underlying.count == 0)
        }
    }
}
