import Testing
import Carrier_Primitives_Test_Support

// Span, MutableSpan, RawSpan, MutableRawSpan are ~Escapable. The
// `Carrier where Underlying == Self` default extension does NOT cover
// the ~Escapable quadrant (its candidacy is gated to Self: Escapable),
// so each Span variant ships explicit witnesses with @_lifetime
// annotations. See Research/sli-span-family.md (v1.1.0) and
// Experiments/span-carrier-conformance/.

@Suite("Span (Carrier conformance)")
struct SpanCarrierTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

// MARK: - Edge Case
//
// Type-level conformance: ~Escapable values can only exist within a
// scoped lifetime context, so type-level checks are the appropriate
// shape for confirming the conformance is present in the module's
// conformance table.

extension SpanCarrierTests.`Edge Case` {

    @Test
    func `Span family conforms at the type level`() {
        func _requireCarrier<T: Carrier & ~Copyable & ~Escapable>(_: T.Type) {}
        _requireCarrier(Span<UInt8>.self)
        _requireCarrier(MutableSpan<UInt8>.self)
        _requireCarrier(RawSpan.self)
        _requireCarrier(MutableRawSpan.self)
        #expect(Bool(true))
    }
}

// MARK: - Unit
//
// Runtime exercise of the explicit witness body for Span<UInt8>.

extension SpanCarrierTests.Unit {

    @Test
    func `Span underlying yields self via _read coroutine`() {
        // Inside a scoped buffer, .underlying yields the same span;
        // count round-trips, confirming the witness routes through the
        // protocol's @_lifetime(borrow self) _read accessor without
        // breaking the lifetime dependency.
        let bytes: [UInt8] = [10, 20, 30]
        bytes.withUnsafeBufferPointer { buffer in
            let span = Span<UInt8>(_unsafeElements: buffer)
            #expect(span.underlying.count == 3)
        }
    }
}
