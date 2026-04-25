import Testing
import Carrier_Primitives_Test_Support

// MutableRawSpan is ~Escapable. Conformance is a one-line typealias
// backed by `extension Carrier where Underlying == Self, Self: ~Escapable`.

@Suite("MutableRawSpan+Carrier")
struct MutableRawSpanCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension MutableRawSpanCarrierTests.Unit {

    @Test
    func `MutableRawSpan underlying yields self via _read coroutine`() {
        var bytes: [UInt8] = [1, 2, 3, 4]
        unsafe bytes.withUnsafeMutableBufferPointer { buffer in
            var span = unsafe MutableSpan<UInt8>(_unsafeElements: buffer)
            let raw = MutableRawSpan(_elements: &span)
            #expect(raw.underlying.byteCount == 4)
        }
    }
}

extension MutableRawSpanCarrierTests.`Edge Case` {

    @Test
    func `MutableRawSpan conforms at the type level`() {
        func _requireCarrier<T: Carrier & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(MutableRawSpan.self)
        #expect(Bool(true))
    }
}
