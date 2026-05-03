import Carrier_Primitives_Test_Support
import Testing

// Span<Element> is ~Escapable. Conformance is a one-line typealias —
// `underlying` and `init(_:)` are provided by the default
// `extension Carrier where Underlying == Self, Self: ~Escapable`. See
// Research/sli-span-family.md (v1.2.0) and
// Experiments/relax-trivial-self-default/.

@Suite
struct `Span+Carrier Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Span+Carrier Tests`.Unit {

    @Test
    func `Span underlying yields self via _read coroutine`() {
        // Inside a scoped buffer, .underlying yields the same span;
        // count round-trips, confirming the witness routes through the
        // protocol's @_lifetime(borrow self) _read accessor without
        // breaking the lifetime dependency.
        let bytes: [UInt8] = [10, 20, 30]
        unsafe bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span<UInt8>(_unsafeElements: buffer)
            #expect(span.underlying.count == 3)
        }
    }
}

extension `Span+Carrier Tests`.`Edge Case` {

    @Test
    func `Span<UInt8> conforms at the type level`() {
        func _requireCarrier<T: Carrier.`Protocol` & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(Span<UInt8>.self)
        #expect(Bool(true))
    }

    @Test
    func `Span underlying preserves empty buffer`() {
        let bytes: [UInt8] = []
        unsafe bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span<UInt8>(_unsafeElements: buffer)
            let isEmpty = span.underlying.isEmpty
            #expect(isEmpty)
        }
    }

    @Test
    func `Span underlying preserves single-element buffer`() {
        let bytes: [UInt8] = [42]
        unsafe bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span<UInt8>(_unsafeElements: buffer)
            #expect(span.underlying.count == 1)
        }
    }
}

extension `Span+Carrier Tests`.Integration {

    @Test
    func `Span satisfies generic Carrier<Span<UInt8>> dispatch`() {
        let bytes: [UInt8] = [1, 2, 3, 4, 5]
        unsafe bytes.withUnsafeBufferPointer { buffer in
            let span = unsafe Span<UInt8>(_unsafeElements: buffer)
            // Generic helper accepting any Carrier whose Underlying is
            // Span<UInt8>. Returns Int, no @_lifetime needed.
            func _count<C: Carrier.`Protocol` & ~Escapable>(
                _ c: borrowing C
            ) -> Int where C.Underlying == Span<UInt8> {
                c.underlying.count
            }
            #expect(_count(span) == 5)
        }
    }
}
