import Testing
import Carrier_Primitives_Test_Support

// RawSpan is ~Escapable. Conformance is a one-line typealias backed by
// `extension Carrier where Underlying == Self, Self: ~Escapable`.

@Suite
struct `RawSpan+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `RawSpan+Carrier Tests`.Unit {

    @Test
    func `RawSpan underlying yields self via _read coroutine`() {
        let bytes: [UInt8] = [1, 2, 3, 4]
        unsafe bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span<UInt8>(_unsafeElements: buffer)
            let raw = RawSpan(_elements: span)
            #expect(raw.underlying.byteCount == 4)
        }
    }
}

extension `RawSpan+Carrier Tests`.`Edge Case` {

    @Test
    func `RawSpan conforms at the type level`() {
        func _requireCarrier<T: Carrier & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(RawSpan.self)
        #expect(Bool(true))
    }

    @Test
    func `RawSpan underlying preserves empty buffer`() {
        let bytes: [UInt8] = []
        unsafe bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span<UInt8>(_unsafeElements: buffer)
            let raw = RawSpan(_elements: span)
            #expect(raw.underlying.byteCount == 0)
        }
    }
}
