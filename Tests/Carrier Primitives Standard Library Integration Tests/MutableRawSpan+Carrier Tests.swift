import Carrier_Primitives_Test_Support
import Testing

// MutableRawSpan is ~Escapable. Conformance is a one-line typealias
// backed by `extension Carrier where Underlying == Self, Self: ~Escapable`.

@Suite
struct `MutableRawSpan+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `MutableRawSpan+Carrier Tests`.Unit {

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

extension `MutableRawSpan+Carrier Tests`.`Edge Case` {

    @Test
    func `MutableRawSpan conforms at the type level`() {
        func _requireCarrier<T: Carrier.`Protocol` & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(MutableRawSpan.self)
        #expect(Bool(true))
    }
}
