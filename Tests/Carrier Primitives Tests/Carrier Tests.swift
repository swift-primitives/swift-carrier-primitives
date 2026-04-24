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
    func `Plain stores and reads Int underlying`() {
        let c = Fixture.Plain(42)
        #expect(c.underlying == 42)
    }

    @Test
    func `Plain round-trips via init from underlying`() {
        let a = Fixture.Plain(100)
        let b = Fixture.Plain(a.underlying)
        #expect(a.underlying == b.underlying)
    }

    @Test
    func `Unique reads underlying via borrow`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: 99))
        let raw = c.underlying.raw
        #expect(raw == 99)
    }

    @Test
    func `describe reflects Underlying and Domain at type level`() {
        let c = Fixture.Plain(7)
        let desc = Fixture.describe(c)
        #expect(desc == "Carrier<Int> with Domain Never")
    }

    @Test
    func `value accepts Plain via parameterized constraint`() {
        let c = Fixture.Plain(55)
        #expect(Fixture.value(of: c) == 55)
    }

    @Test
    func `Scoped conforms with noncopyable nonescapable underlying`() {
        let c = Fixture.Scoped(Fixture.Scoped.Resource(raw: 77))
        let raw = c.underlying.raw
        #expect(raw == 77)
    }
}
