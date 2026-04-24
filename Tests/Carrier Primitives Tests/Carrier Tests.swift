import Testing
import Carrier_Primitives
import Carrier_Primitives_Test_Support

// Carrier<Underlying> is a generic protocol — per [SWIFT-TEST-003] the
// test suite uses the parallel namespace pattern (a non-generic
// top-level struct).

@Suite("Carrier")
struct CarrierTests {
    @Suite struct Unit {}
}

extension CarrierTests.Unit {

    @Test
    func `IntCarrier stores and reads Int underlying`() {
        let c = IntCarrier(42)
        #expect(c.underlying == 42)
    }

    @Test
    func `IntCarrier round-trips via init from underlying`() {
        let a = IntCarrier(100)
        let b = IntCarrier(a.underlying)
        #expect(a.underlying == b.underlying)
    }

    @Test
    func `MoveOnlyCarrier reads underlying via borrow`() {
        let c = MoveOnlyCarrier(MoveOnly(raw: 99))
        let raw = c.underlying.raw
        #expect(raw == 99)
    }

    @Test
    func `generic describe over any Carrier dispatches`() {
        let c = IntCarrier(7)
        let desc = describe(c)
        #expect(desc == "Carrier<Int> with Domain Never")
    }

    @Test
    func `extractInt accepts IntCarrier via parameterized constraint`() {
        let c = IntCarrier(55)
        #expect(extractInt(c) == 55)
    }
}
