import Testing
import Carrier_Primitives_Test_Support

// Q2 (~Copyable & Escapable Underlying) fixture — the carrier is
// ~Copyable because its Underlying is. Underlying remains Escapable,
// so `@_lifetime` annotations are still omitted. The getter uses a
// `_read { yield }` coroutine for borrowing access.

@Suite("Fixture.Unique")
struct FixtureUniqueTests {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension FixtureUniqueTests.Unit {

    @Test
    func `Unique reads underlying via borrow`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: 99))
        let raw = c.underlying.raw
        #expect(raw == 99)
    }
}

extension FixtureUniqueTests.`Edge Case` {

    @Test
    func `Unique handles raw zero`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: 0))
        #expect(c.underlying.raw == 0)
    }

    @Test
    func `Unique handles negative raw`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: -1))
        #expect(c.underlying.raw == -1)
    }
}

extension FixtureUniqueTests.Integration {

    @Test
    func `Unique satisfies generic Carrier reflection`() {
        let c = Fixture.Unique(Fixture.Unique.Resource(raw: 1))
        // `_read` yield path drives the generic describe call.
        let desc = Fixture.describe(c)
        #expect(desc == "Carrier<Resource> with Domain Never")
    }
}
